import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/data/remote/api/providers/http_service_provider.dart';
import 'package:flutter_riverpod_template/data/remote/api/service/http_service.dart';
import 'package:flutter_riverpod_template/data/remote/graphql/graphql_service_provider.dart';
import 'package:flutter_riverpod_template/data/remote/graphql/native_graphql_service.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_master_data.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_service_item_model.dart';
import 'package:flutter_riverpod_template/feature/claims/models/diagnosis_model.dart';

final claimMasterDataStoreProvider = Provider<ClaimMasterDataStore>(
  (ref) => ClaimMasterDataStore(),
);

final claimSetupRepositoryProvider = Provider<ClaimSetupRepository>((ref) {
  return ClaimSetupRepository(
    ref.watch(httpServiceProvider),
    ref.watch(graphQLServiceProvider),
    ref.watch(claimMasterDataStoreProvider),
  );
});

class ClaimSetupRepository {
  ClaimSetupRepository(this._http, this._graphql, this._store);

  final HttpService _http;
  final NativeGraphQLService _graphql;
  final ClaimMasterDataStore _store;

  Future<ClaimMasterData> initialize(
    String claimAdministratorCode, {
    void Function(String message)? onProgress,
  }) async {
    final code = claimAdministratorCode.trim();
    if (code.isEmpty) {
      throw const FormatException('Please enter Claim Admin Code.');
    }

    onProgress?.call('Validating Claim Administrator…');
    final administrator = await _loadAdministrator(code);

    onProgress?.call('Checking for updates');
    final diagnoses = await _loadDiagnoses();

    onProgress?.call('Diagnoses, Services, Items…');
    final mapped = await _loadMappedCatalog(code);

    final result = ClaimMasterData(
      administrator: ClaimAdministratorProfile(
        code: administrator.code,
        displayName: administrator.displayName,
        healthFacilityCode: mapped.$3.isNotEmpty
            ? mapped.$3
            : administrator.healthFacilityCode,
        healthFacilityName: mapped.$4.isNotEmpty
            ? mapped.$4
            : administrator.healthFacilityName,
      ),
      diagnoses: diagnoses,
      services: mapped.$1,
      items: mapped.$2,
    );
    _store.value = result;
    return result;
  }

  Future<ClaimAdministratorProfile> _loadAdministrator(String code) async {
    final response = await _http.get<Map<String, dynamic>>(
      'api/api_fhir_r4/Practitioner/',
      queryParameters: {'resourceType': 'ca', 'identifier': code},
    );
    final entries = response.data?['entry'];
    if (entries is! List || entries.isEmpty) {
      throw const FormatException('Invalid Claim Admin Code.');
    }
    Map<String, dynamic>? practitioner;
    for (final entry in entries) {
      final candidate = _map(_map(entry)['resource']);
      final candidateCode = _claimAdminCode(candidate['identifier']);
      if (candidateCode.toLowerCase() == code.toLowerCase()) {
        practitioner = candidate;
        break;
      }
    }
    if (practitioner == null) {
      throw const FormatException('Invalid Claim Admin Code.');
    }
    final returnedCode = _claimAdminCode(practitioner['identifier']);
    final name = _firstMap(practitioner['name']);
    final given = name['given'] is List
        ? (name['given'] as List).map((value) => value.toString()).join(' ')
        : '';
    final family = name['family']?.toString() ?? '';
    final facility = _map(practitioner['healthFacility']);
    final extensionFacilityCode = _organizationCodeFromExtensions(
      practitioner['extension'],
    );
    return ClaimAdministratorProfile(
      code: returnedCode,
      displayName: [given, family].where((part) => part.isNotEmpty).join(' '),
      healthFacilityCode: facility['code']?.toString() ?? extensionFacilityCode,
      healthFacilityName: facility['name']?.toString() ?? '',
    );
  }

  Future<List<Diagnosis>> _loadDiagnoses() async {
    final response = await _http.get<Map<String, dynamic>>(
      'api/api_fhir_r4/CodeSystem/diagnosis/',
    );
    final concepts = response.data?['concept'];
    if (concepts is! List || concepts.isEmpty) {
      throw const FormatException('No diagnoses returned by openIMIS.');
    }
    return concepts
        .map(_map)
        .map(
          (item) => Diagnosis(
            code: item['code']?.toString() ?? '',
            name: item['display']?.toString() ?? '',
          ),
        )
        .where((item) => item.code.isNotEmpty)
        .toList(growable: false);
  }

  Future<(List<MedicalService>, List<MedicationItem>, String, String)>
  _loadMappedCatalog(String code) async {
    final data = await _graphql.query(_catalogQuery, variables: {'code': code});
    final admins = _map(data['claimAdmins']);
    final edges = admins['edges'];
    if (edges is! List || edges.isEmpty) {
      throw const FormatException(
        'No price list found for Claim Administrator.',
      );
    }
    final node = _map(_map(edges.first)['node']);
    final facility = _map(node['healthFacility']);
    final services = _catalogEdges(
      facility['servicesPricelist'],
    ).map((item) => MedicalService.fromJson(item)).toList(growable: false);
    final items = _catalogEdges(
      facility['itemsPricelist'],
    ).map((item) => MedicationItem.fromJson(item)).toList(growable: false);
    if (services.isEmpty || items.isEmpty) {
      throw const FormatException('Services and items mapping is incomplete.');
    }
    return (
      services,
      items,
      facility['code']?.toString() ?? '',
      facility['name']?.toString() ?? '',
    );
  }

  static String _organizationCodeFromExtensions(dynamic value) {
    if (value is! List) return '';
    for (final extension in value) {
      final reference = _map(_map(extension)['valueReference']);
      if (reference['type']?.toString() != 'Organization') continue;
      final identifier = _map(reference['identifier']);
      final code = identifier['value']?.toString() ?? '';
      if (code.isNotEmpty) return code;
    }
    return '';
  }

  static String _claimAdminCode(dynamic value) {
    if (value is! List) return '';
    String fallback = '';
    for (final rawIdentifier in value) {
      final identifier = _map(rawIdentifier);
      final identifierValue = identifier['value']?.toString() ?? '';
      if (identifierValue.isEmpty) continue;
      fallback = identifierValue;
      final type = _map(identifier['type']);
      final coding = type['coding'];
      if (coding is! List) continue;
      for (final rawCode in coding) {
        final code = _map(rawCode)['code']?.toString().toLowerCase();
        if (code == 'code') return identifierValue;
      }
    }
    return fallback;
  }

  static Iterable<Map<String, dynamic>> _catalogEdges(dynamic priceList) sync* {
    final details = _map(_map(priceList)['details']);
    final edges = details['edges'];
    if (edges is! List) return;
    for (final edge in edges) {
      final node = _map(_map(edge)['node']);
      final item = _map(node['service'] ?? node['item']);
      if (item.isNotEmpty) yield item;
    }
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static Map<String, dynamic> _firstMap(dynamic value) =>
      value is List && value.isNotEmpty
      ? _map(value.first)
      : <String, dynamic>{};

  static const _catalogQuery = r'''
query ClaimMobileSetup($code: String) {
  claimAdmins(code: $code) {
    edges {
      node {
        code
        healthFacility {
          code
          name
          servicesPricelist { details { edges { node { service { code name price } } } } }
          itemsPricelist { details { edges { node { item { code name price } } } } }
        }
      }
    }
  }
}''';
}
