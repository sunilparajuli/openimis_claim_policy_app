import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/graphql_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';

final policyEnrollmentRepositoryProvider = Provider<PolicyEnrollmentRepository>(
  (ref) => PolicyEnrollmentRepository(ref.watch(graphQLServiceProvider)),
);

class EnrollmentMutationResult {
  const EnrollmentMutationResult({
    required this.clientMutationId,
    this.internalId,
  });

  final String clientMutationId;
  final int? internalId;
}

class MutationLogResult {
  const MutationLogResult({required this.status, this.error});

  /// openIMIS MutationLog: 0 received, 1 error, 2 success.
  final int status;
  final String? error;

  bool get pending => status == 0;
  bool get failed => status == 1;
  bool get succeeded => status == 2;
}

class FamilyServerReference {
  const FamilyServerReference({required this.id, required this.uuid});

  final int id;
  final String uuid;
}

class PolicyEnrollmentRepository {
  const PolicyEnrollmentRepository(this._graphql);

  final NativeGraphQLService _graphql;

  Future<EnrollmentMutationResult> createFamily(
    PolicyFamilyDraft family, {
    required String clientMutationId,
  }) async {
    final data = await _graphql.mutate(
      _createFamilyMutation,
      variables: {'input': family.toGraphQLInput(clientMutationId)},
      options: _mutationOptions,
    );
    return _result(data, 'createFamily', clientMutationId);
  }

  Future<EnrollmentMutationResult> createInsuree(
    PolicyInsureeDraft insuree, {
    required PolicyApplication application,
    required int familyId,
    required String clientMutationId,
  }) async {
    final input =
        insuree.toGraphQLInput(application, resolvedFamilyId: familyId)
          ..addAll({
            'clientMutationId': clientMutationId,
            'clientMutationLabel': 'Create Insuree',
          });
    final data = await _graphql.mutate(
      _createInsureeMutation,
      variables: {'input': input},
      options: _mutationOptions,
    );
    return _result(data, 'createInsuree', clientMutationId);
  }

  Future<EnrollmentMutationResult> updateInsuree(
    PolicyInsureeDraft insuree, {
    required PolicyApplication application,
    required String clientMutationId,
  }) async {
    if (insuree.uuid?.isNotEmpty != true) {
      throw const FormatException('Insuree UUID is required for an update.');
    }
    final input = insuree.toGraphQLInput(application)
      ..addAll({
        'clientMutationId': clientMutationId,
        'clientMutationLabel': 'Update Insuree',
      });
    final data = await _graphql.mutate(
      _updateInsureeMutation,
      variables: {'input': input},
      options: _mutationOptions,
    );
    return _result(data, 'updateInsuree', clientMutationId);
  }

  Future<PolicyInsureeDraft> insureeForEdit(
    String chfId, {
    required PolicyApplication application,
  }) async {
    final data = await _graphql.query(
      _insureeForEditQuery,
      variables: {'chfId': chfId},
      options: _mutationOptions,
    );
    final insurees = data['insurees'];
    final edges = insurees is Map ? insurees['edges'] : null;
    if (edges is! List || edges.isEmpty) {
      throw FormatException('No insuree found for MPI $chfId.');
    }
    final edge = edges.first;
    final node = edge is Map ? edge['node'] : null;
    if (node is! Map) throw const FormatException('Invalid insuree response.');
    if (application == PolicyApplication.hiv &&
        node['email']?.toString() != hivInsureeMarkerEmail) {
      throw const FormatException('The MPI is not an HIV beneficiary.');
    }
    final gender = node['gender'];
    final family = node['family'];
    return PolicyInsureeDraft(
      uuid: node['uuid']?.toString(),
      chfId: node['chfId']?.toString() ?? chfId,
      lastName: node['lastName']?.toString() ?? '',
      otherNames: node['otherNames']?.toString() ?? '',
      genderId: gender is Map ? gender['code']?.toString() ?? '' : '',
      dateOfBirth: DateTime.parse(node['dob'].toString()),
      familyId: family is Map
          ? int.tryParse(family['legacyId']?.toString() ?? '')
          : null,
      isHead: node['head'] == true,
      phone: node['phone']?.toString(),
      email: node['email']?.toString(),
      cardIssued: node['cardIssued'] == true,
    );
  }

  Future<EnrollmentMutationResult> createPolicy(
    PolicyDraft policy, {
    required String clientMutationId,
  }) async {
    final data = await _graphql.mutate(
      _createPolicyMutation,
      variables: {'input': policy.toGraphQLInput(clientMutationId)},
      options: _mutationOptions,
    );
    return _result(data, 'createPolicy', clientMutationId);
  }

  Future<MutationLogResult?> mutationStatus(String clientMutationId) async {
    final data = await _graphql.query(
      _mutationLogQuery,
      variables: {'clientMutationId': clientMutationId},
      options: _mutationOptions,
    );
    final logs = data['mutationLogs'];
    final edges = logs is Map ? logs['edges'] : null;
    if (edges is! List || edges.isEmpty) return null;
    final edge = edges.first;
    final node = edge is Map ? edge['node'] : null;
    if (node is! Map || node['status'] == null) return null;
    final status = int.tryParse(node['status'].toString());
    if (status == null) return null;
    return MutationLogResult(status: status, error: node['error']?.toString());
  }

  Future<MutationLogResult> waitForMutation(
    String clientMutationId, {
    Duration timeout = const Duration(minutes: 5),
    Duration interval = const Duration(milliseconds: 1500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final result = await mutationStatus(clientMutationId);
      if (result != null && !result.pending) {
        if (result.failed) {
          throw StateError(_mutationError(result.error));
        }
        return result;
      }
      await Future<void>.delayed(interval);
    }
    throw TimeoutException(
      'Mutation $clientMutationId did not finish within ${timeout.inSeconds}s.',
    );
  }

  /// Resolves the database family ID after createFamily has completed. The
  /// mutation's internalId is the MutationLog ID, not the created family ID.
  Future<int> familyIdForHead(String chfId) async {
    return (await familyForHead(chfId)).id;
  }

  Future<FamilyServerReference> familyForHead(String chfId) async {
    final data = await _graphql.query(
      _familyByHeadQuery,
      variables: {'headChfId': chfId},
      options: _mutationOptions,
    );
    final families = data['families'];
    final edges = families is Map ? families['edges'] : null;
    if (edges is! List || edges.isEmpty) {
      throw FormatException('No family found for MPI $chfId.');
    }
    final edge = edges.first;
    final node = edge is Map ? edge['node'] : null;
    if (node is! Map) throw const FormatException('Invalid family response.');
    final legacyId = int.tryParse(node['legacyId']?.toString() ?? '');
    final uuid = node['uuid']?.toString() ?? '';
    if (legacyId != null) {
      return FamilyServerReference(id: legacyId, uuid: uuid);
    }
    final globalId = node['id']?.toString();
    final decoded = _legacyIdFromGlobalId(globalId);
    if (decoded != null) return FamilyServerReference(id: decoded, uuid: uuid);
    throw const FormatException('Family response has no database ID.');
  }

  Future<bool> policyExistsForFamily(
    String familyUuid,
    String productCode,
  ) async {
    if (familyUuid.isEmpty || productCode.isEmpty) return false;
    final data = await _graphql.query(
      _familyPoliciesQuery,
      variables: {'familyUuid': familyUuid},
      options: _mutationOptions,
    );
    final policies = data['policiesByFamily'];
    final edges = policies is Map ? policies['edges'] : null;
    if (edges is! List) return false;
    return edges.any((edge) {
      final node = edge is Map ? edge['node'] : null;
      return node is Map &&
          node['productCode']?.toString().toUpperCase() ==
              productCode.toUpperCase();
    });
  }

  Future<bool> insureeExists(String chfId) async {
    final data = await _graphql.query(
      _insureeByChfIdQuery,
      variables: {'chfId': chfId},
      options: _mutationOptions,
    );
    final insurees = data['insurees'];
    final edges = insurees is Map ? insurees['edges'] : null;
    return edges is List && edges.isNotEmpty;
  }

  static EnrollmentMutationResult _result(
    Map<String, dynamic> data,
    String field,
    String fallbackMutationId,
  ) {
    final payload = data[field];
    if (payload is! Map) {
      throw FormatException('Missing $field mutation response.');
    }
    return EnrollmentMutationResult(
      clientMutationId:
          payload['clientMutationId']?.toString() ?? fallbackMutationId,
      internalId: int.tryParse(payload['internalId']?.toString() ?? ''),
    );
  }

  static int? _legacyIdFromGlobalId(String? value) {
    if (value == null || value.isEmpty) return null;
    final direct = int.tryParse(value);
    if (direct != null) return direct;
    try {
      final normalized = base64.normalize(value);
      final decoded = utf8.decode(base64.decode(normalized));
      return int.tryParse(decoded.split(':').last);
    } catch (_) {
      return null;
    }
  }

  static String _mutationError(String? raw) {
    if (raw == null || raw.isEmpty) return 'The server rejected the mutation.';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final details = decoded
            .whereType<Map>()
            .map((item) => item['detail']?.toString())
            .whereType<String>()
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        if (details.isNotEmpty) return details.join('\n');
      }
    } catch (_) {
      // Some deployments return a translated plain-text error.
    }
    return raw;
  }

  static final _mutationOptions = Options(extra: const {'no_retry': true});

  static const _createFamilyMutation = r'''
mutation CreateMobileFamily($input: CreateFamilyMutationInput!) {
  createFamily(input: $input) { clientMutationId internalId }
}''';

  static const _createInsureeMutation = r'''
mutation CreateMobileInsuree($input: CreateInsureeMutationInput!) {
  createInsuree(input: $input) { clientMutationId internalId }
}''';

  static const _createPolicyMutation = r'''
mutation CreateMobilePolicy($input: CreatePolicyMutationInput!) {
  createPolicy(input: $input) { clientMutationId internalId }
}''';

  static const _updateInsureeMutation = r'''
mutation UpdateMobileInsuree($input: UpdateInsureeMutationInput!) {
  updateInsuree(input: $input) { clientMutationId internalId }
}''';

  static const _mutationLogQuery = r'''
query MobileMutationStatus($clientMutationId: String) {
  mutationLogs(
    clientMutationId: $clientMutationId
    orderBy: ["-requestDateTime"]
  ) {
    edges { node { status error } }
  }
}''';

  static const _familyByHeadQuery = r'''
query MobileFamilyByHead($headChfId: String) {
  families(headInsuree_ChfId: $headChfId, first: 1) {
    edges { node { id legacyId uuid } }
  }
}''';

  static const _insureeByChfIdQuery = r'''
query MobileInsureeExists($chfId: String) {
  insurees(chfId: $chfId, first: 1) { edges { node { id chfId } } }
}''';

  static const _familyPoliciesQuery = r'''
query MobileFamilyPolicies($familyUuid: String!) {
  policiesByFamily(
    familyUuid: $familyUuid
    activeOrLastExpiredOnly: true
    first: 100
  ) {
    edges { node { policyUuid productCode status } }
  }
}''';

  static const _insureeForEditQuery = r'''
query MobileInsureeForEdit($chfId: String) {
  insurees(chfId: $chfId, ignoreLocation: true, first: 1) {
    edges {
      node {
        uuid chfId lastName otherNames dob head phone email cardIssued
        gender { code }
        family { legacyId uuid }
      }
    }
  }
}''';
}
