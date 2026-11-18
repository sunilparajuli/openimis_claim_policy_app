import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/remote/api/providers/http_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/http_service.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/graphql_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_master_data.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_service_item_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/diagnosis_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_program.dart';
import 'package:openimis_claim_policy_app/feature/claims/data/local/claim_master_data_cache.dart';
import 'package:openimis_claim_policy_app/data/remote/api/error/api_error.dart';

final claimMasterDataStoreProvider = Provider<ClaimMasterDataStore>(
  (ref) => ClaimMasterDataStore(),
);

final claimSetupRepositoryProvider = Provider<ClaimSetupRepository>((ref) {
  return ClaimSetupRepository(
    ref.watch(httpServiceProvider),
    ref.watch(graphQLServiceProvider),
    ref.watch(claimMasterDataStoreProvider),
    const ClaimMasterDataCache(),
  );
});

class ClaimSetupRepository {
  ClaimSetupRepository(
    this._http,
    this._graphql,
    this._store, [
    this._cache = const ClaimMasterDataCache(),
  ]);

  final HttpService _http;
  final NativeGraphQLService _graphql;
  final ClaimMasterDataStore _store;
  final ClaimMasterDataCache _cache;

  Future<ClaimMasterData> initialize(
    String claimAdministratorCode, {
    void Function(String message)? onProgress,
  }) async {
    final code = claimAdministratorCode.trim();
    if (code.isEmpty) {
      throw const FormatException('Please enter Claim Admin Code.');
    }

    try {
      return await _synchronize(code, onProgress: onProgress);
    } catch (error) {
      if (error is FormatException ||
          error is ApiError &&
              const {
                ApiErrorType.client,
                ApiErrorType.unauthorized,
                ApiErrorType.forbidden,
                ApiErrorType.notFound,
              }.contains(error.type)) {
        rethrow;
      }
      onProgress?.call('Loading offline claim catalogue…');
      final cached = await _cache.load(code);
      if (cached == null) rethrow;
      _store.value = cached;
      return cached;
    }
  }

  Future<ClaimMasterData> _synchronize(
    String code, {
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Validating Claim Administrator…');
    final administrator = await _loadAdministrator(code);

    onProgress?.call('Checking for updates');
    final diagnoses = await _loadDiagnoses();

    onProgress?.call('Programs…');
    final programs = await _loadPrograms();

    onProgress?.call('Diagnoses, Services, Items…');
    final mapped = await _loadMappedCatalog(code);
    final eligible = await _loadEligibleCatalog(mapped.$6);
    final services = _mergeServices(mapped.$1, eligible.$1);
    final items = _mergeItems(mapped.$2, eligible.$2);

    final result = ClaimMasterData(
      administrator: ClaimAdministratorProfile(
        id: mapped.$5.isNotEmpty ? mapped.$5 : administrator.id,
        code: administrator.code,
        displayName: administrator.displayName,
        healthFacilityCode: mapped.$3.isNotEmpty
            ? mapped.$3
            : administrator.healthFacilityCode,
        healthFacilityName: mapped.$4.isNotEmpty
            ? mapped.$4
            : administrator.healthFacilityName,
        healthFacilityId: mapped.$6.isNotEmpty
            ? mapped.$6
            : administrator.healthFacilityId,
      ),
      diagnoses: diagnoses,
      services: services,
      items: items,
      programs: programs,
    );
    _store.value = result;
    await _cache.save(result);
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
      id: practitioner['id']?.toString(),
      displayName: [given, family].where((part) => part.isNotEmpty).join(' '),
      healthFacilityCode: facility['code']?.toString() ?? extensionFacilityCode,
      healthFacilityName: facility['name']?.toString() ?? '',
      healthFacilityId: facility['id']?.toString(),
    );
  }

  Future<List<Diagnosis>> _loadDiagnoses() async {
    final data = await _graphql.query(
      _diagnosesQuery,
      variables: {'offset': 0},
    );
    final edges = _map(data['diagnoses'])['edges'];
    if (edges is! List || edges.isEmpty) {
      throw const FormatException('No diagnoses returned by openIMIS.');
    }
    return edges
        .map(_map)
        .map((edge) => Diagnosis.fromJson(_map(edge['node'])))
        .where((item) => item.code.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<ClaimProgram>> _loadPrograms() async {
    final data = await _graphql.query(
      _programsQuery,
      variables: {'first': 100},
    );
    final edges = _map(data['program'])['edges'];
    if (edges is! List || edges.isEmpty) {
      throw const FormatException('No programs returned by openIMIS.');
    }
    return edges
        .map(_map)
        .map((edge) => ClaimProgram.fromJson(_map(edge['node'])))
        .where((program) => program.code.isNotEmpty)
        .toList(growable: false);
  }

  Future<
    (List<MedicalService>, List<MedicationItem>, String, String, String, String)
  >
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
      node['id']?.toString() ?? '',
      facility['id']?.toString() ?? '',
    );
  }

  Future<(List<MedicalService>, List<MedicationItem>)> _loadEligibleCatalog(
    String healthFacilityId,
  ) async {
    if (healthFacilityId.isEmpty) {
      return (const <MedicalService>[], const <MedicationItem>[]);
    }
    final data = await _graphql.query(
      _eligibleCatalogQuery,
      variables: {'healthFacilityId': healthFacilityId},
    );
    final services = _connectionNodes(data['medicalServices'])
        .map(MedicalService.fromJson)
        .where((service) => service.code.isNotEmpty)
        .toList(growable: false);
    final items = _connectionNodes(data['medicalItems'])
        .map(MedicationItem.fromJson)
        .where((item) => item.code.isNotEmpty)
        .toList(growable: false);
    return (services, items);
  }

  static List<MedicalService> _mergeServices(
    List<MedicalService> priced,
    List<MedicalService> eligible,
  ) {
    final byCode = {for (final service in eligible) service.code: service};
    for (final priceListService in priced) {
      final metadata = byCode[priceListService.code];
      byCode[priceListService.code] = MedicalService(
        id: metadata?.id ?? priceListService.id,
        code: priceListService.code,
        name: priceListService.name,
        price: priceListService.price,
        category: metadata?.category ?? priceListService.category,
        programCode: metadata?.programCode ?? priceListService.programCode,
      );
    }
    return byCode.values.toList(growable: false);
  }

  static List<MedicationItem> _mergeItems(
    List<MedicationItem> priced,
    List<MedicationItem> eligible,
  ) {
    final byCode = {for (final item in eligible) item.code: item};
    for (final priceListItem in priced) {
      final metadata = byCode[priceListItem.code];
      byCode[priceListItem.code] = MedicationItem(
        id: metadata?.id ?? priceListItem.id,
        code: priceListItem.code,
        name: priceListItem.name,
        price: priceListItem.price,
        unit: metadata?.unit ?? priceListItem.unit,
        programCode: metadata?.programCode ?? priceListItem.programCode,
      );
    }
    return byCode.values.toList(growable: false);
  }

  static Iterable<Map<String, dynamic>> _connectionNodes(
    dynamic connection,
  ) sync* {
    final edges = _map(connection)['edges'];
    if (edges is! List) return;
    for (final edge in edges) {
      final node = _map(_map(edge)['node']);
      if (node.isNotEmpty) yield node;
    }
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
        id
        code
        healthFacility {
          id
          code
          name
          servicesPricelist { details { edges { node { service { code name price program { code nameProgram } } } } } }
          itemsPricelist { details { edges { node { item { code name price program { code nameProgram } } } } } }
        }
      }
    }
  }
}''';

  static const _diagnosesQuery = r'''
query ClaimDiagnoses($offset: Int) {
  diagnoses(offset: $offset) {
    edges { node { id code name } }
  }
}''';

  static const _programsQuery = r'''
query ClaimPrograms($first: Int) {
  program(first: $first) {
    edges { node { idProgram code nameProgram } }
  }
}''';

  static const _eligibleCatalogQuery = r'''
query ClaimEligibleCatalog($healthFacilityId: ID) {
  medicalServices(healthFacilityId: $healthFacilityId) {
    edges {
      node {
        id code name price type
        program { code nameProgram }
        healthFacility { id code }
      }
    }
  }
  medicalItems(healthFacilityId: $healthFacilityId) {
    edges {
      node {
        id code name price type
        program { code nameProgram }
        healthFacility { id code }
      }
    }
  }
}''';
}
