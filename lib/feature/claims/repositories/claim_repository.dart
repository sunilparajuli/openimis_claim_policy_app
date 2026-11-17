import 'dart:async';
import 'dart:convert';

import 'package:openimis_claim_policy_app/data/remote/api/providers/http_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/http_service.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_service_item_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_master_data.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/diagnosis_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_program.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_setup_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/graphql_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';

part 'claim_repository.g.dart';

@riverpod
ClaimRepository claimRepository(Ref ref) {
  final http = ref.watch(httpServiceProvider);
  return ClaimRepository(
    http,
    ref.watch(claimMasterDataStoreProvider),
    ref.watch(graphQLServiceProvider),
  );
}

class ClaimRepository {
  ClaimRepository(
    HttpService http, [
    ClaimMasterDataStore? masterData,
    NativeGraphQLService? graphql,
  ]) : _masterData = masterData ?? ClaimMasterDataStore(),
       _graphql = graphql ?? NativeGraphQLService(http);

  final ClaimMasterDataStore _masterData;
  final NativeGraphQLService _graphql;

  /// Submits a mobile claim using the CSU GraphQL contract.
  Future<bool> submitClaim(ClaimSubmission claim) async {
    final programId = _requiredId(claim.program?.id, 'claim program');
    final healthFacilityId = _requiredId(
      claim.healthFacilityId,
      'health facility',
    );
    final claimAdminId = _requiredId(claim.claimAdminId, 'claim administrator');
    final diagnosisId = _requiredId(
      claim.primaryDiagnosis.id,
      'primary diagnosis',
    );
    final insureeId = await _loadInsureeId(claim.insureeChfId);

    final clientMutationId =
        '${claim.claimCode}-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final input = <String, dynamic>{
      'clientMutationId': clientMutationId,
      'clientMutationLabel': 'create claim ${claim.claimCode}',
      'code': claim.claimCode,
      'insureeId': insureeId,
      'adminId': claimAdminId,
      'dateFrom': _date(claim.startDate),
      'dateTo': _date(claim.endDate),
      'icdId': diagnosisId,
      'dateClaimed': _date(claim.claimDate),
      'healthFacilityId': healthFacilityId,
      'program': programId,
      'visitType': claim.visitType.code,
      'source': 'MOB',
      if (claim.guaranteeNo?.isNotEmpty == true)
        'guaranteeId': claim.guaranteeNo,
      'services': claim.services
          .map(
            (entry) => {
              'serviceId': _requiredId(
                entry.service.id,
                'service ${entry.service.code}',
              ),
              'priceAsked': entry.price,
              'qtyProvided': entry.quantity,
              'status': 1,
            },
          )
          .toList(growable: false),
      'items': claim.items
          .map(
            (entry) => {
              'itemId': _requiredId(entry.item.id, 'item ${entry.item.code}'),
              'priceAsked': entry.price,
              'qtyProvided': entry.quantity,
              'status': 1,
            },
          )
          .toList(growable: false),
    };

    final data = await _graphql.mutate(
      _createClaimMutation,
      variables: {'input': input},
      options: Options(extra: const {'no_retry': true}),
    );
    if (!data.containsKey('createClaim')) return false;
    await _waitForClaimMutation(clientMutationId, claim.claimCode);
    return true;
  }

  Future<void> _waitForClaimMutation(
    String clientMutationId,
    String claimCode, {
    Duration timeout = const Duration(minutes: 10),
    Duration interval = const Duration(milliseconds: 1500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final data = await _graphql.query(
        _mutationLogQuery,
        variables: {'clientMutationId': clientMutationId},
        options: Options(extra: const {'no_retry': true}),
      );
      final logs = data['mutationLogs'];
      final edges = logs is Map ? logs['edges'] : null;
      if (edges is List && edges.isNotEmpty) {
        final edge = edges.first;
        final node = edge is Map ? edge['node'] : null;
        final status = node is Map
            ? int.tryParse(node['status']?.toString() ?? '')
            : null;
        if (status == 1) {
          throw FormatException(_claimMutationError(claimCode, node?['error']));
        }
        if (status == 2) return;
      }
      await Future<void>.delayed(interval);
    }
    throw TimeoutException(
      'Claim $claimCode did not finish synchronizing within '
      '${timeout.inSeconds} seconds.',
    );
  }

  static String _claimMutationError(String claimCode, Object? rawError) {
    final raw = rawError?.toString() ?? '';
    final details = <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        details.addAll(
          decoded
              .whereType<Map>()
              .map((item) => item['detail']?.toString())
              .whereType<String>()
              .where((item) => item.isNotEmpty),
        );
      }
    } catch (_) {
      // Some CSU deployments return a translated plain-text error.
    }
    final detail = details.isEmpty ? raw : details.join('\n');
    return detail.isEmpty
        ? 'Error while creating claim \'$claimCode\'.'
        : 'Error while creating claim \'$claimCode\': $detail';
  }

  Future<int> _loadInsureeId(String chfId) async {
    final data = await _graphql.query(
      _insureeQuery,
      variables: {'chfId': chfId},
      options: Options(extra: const {'no_retry': true}),
    );
    final insurees = data['insurees'];
    final edges = insurees is Map ? insurees['edges'] : null;
    if (edges is! List || edges.isEmpty) {
      throw FormatException('No insuree found for MPI $chfId.');
    }
    final edge = edges.first;
    final node = edge is Map ? edge['node'] : null;
    final id = node is Map ? node['id'] : null;
    return _requiredId(id?.toString(), 'insuree');
  }

  static int _requiredId(String? value, String label) {
    final id = int.tryParse(value ?? '');
    if (id == null) throw FormatException('Missing server ID for $label.');
    return id;
  }

  static String _date(DateTime value) =>
      value.toIso8601String().substring(0, 10);

  /// Master list of diagnoses (ICD-10)
  List<Diagnosis> getDiagnoses() {
    return _masterData.value?.diagnoses ?? const [];
  }

  /// Master list of medical services
  List<MedicalService> getAvailableServices() {
    final synchronized = _masterData.value?.services;
    return synchronized ?? const [];
  }

  /// Master list of medications and pharmaceuticals
  List<MedicationItem> getAvailableItems() {
    final synchronized = _masterData.value?.items;
    return synchronized ?? const [];
  }

  List<ClaimProgram> getPrograms() => _masterData.value?.programs ?? const [];

  bool containsDiagnosis(Diagnosis diagnosis) => getDiagnoses().any(
    (candidate) =>
        candidate.code == diagnosis.code &&
        (diagnosis.id == null || candidate.id == diagnosis.id),
  );

  bool containsProgram(ClaimProgram program) => getPrograms().any(
    (candidate) =>
        candidate.code == program.code &&
        (program.id == null || candidate.id == program.id),
  );

  static const _insureeQuery = r'''
query ClaimInsuree($chfId: String) {
  insurees(chfId: $chfId, ignoreLocation: true) {
    edges { node { id chfId } }
  }
}''';

  static const _createClaimMutation = r'''
mutation CreateMobileClaim($input: CreateClaimMutationInput!) {
  createClaim(input: $input) {
    clientMutationId
    internalId
  }
}''';

  static const _mutationLogQuery = r'''
query MobileClaimMutationStatus($clientMutationId: String) {
  mutationLogs(
    clientMutationId: $clientMutationId
    orderBy: ["-requestDateTime"]
  ) {
    edges { node { status error } }
  }
}''';
}
