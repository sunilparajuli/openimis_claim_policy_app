import 'dart:io';

import 'package:dio/dio.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/openimis_mock_interceptor.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/dio_http_service.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_master_data.dart';
import 'package:openimis_claim_policy_app/feature/claims/data/local/claim_master_data_cache.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_setup_repository.dart';
import 'package:openimis_claim_policy_app/feature/login/models/login_request_model.dart';
import 'package:openimis_claim_policy_app/feature/login/repositories/openimis_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DioHttpService http;
  late Directory cacheDirectory;
  late ClaimMasterDataCache cache;

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('claim-cache-test-');
    cache = ClaimMasterDataCache(directory: () async => cacheDirectory);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com/'));
    dio.interceptors.add(OpenImisMockInterceptor(forceDemo: true));
    http = DioHttpService(dio);
  });

  tearDown(() async {
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  });

  test('uses the Java app FHIR login contract', () async {
    final result = await OpenImisAuthRepository(http).login(
      const LoginRequestModel(userName: 'RHOS0011', password: 'RHOS0011'),
    );
    expect(result.token, contains('RHOS0011'));
    expect(result.expiresOn, greaterThan(0));
  });

  test('validates Claim Admin and synchronizes mapped master data', () async {
    final progress = <String>[];
    final store = ClaimMasterDataStore();
    final repository = ClaimSetupRepository(
      http,
      NativeGraphQLService(http),
      store,
      cache,
    );
    final result = await repository.initialize(
      'RHOS0011',
      onProgress: progress.add,
    );

    expect(result.administrator.code, 'RHOS0011');
    expect(result.administrator.healthFacilityCode, 'RAHOS001');
    expect(result.administrator.healthFacilityName, 'Rapta District Hospital');
    expect(result.diagnoses, isNotEmpty);
    expect(result.services, hasLength(30001));
    expect(result.items, hasLength(30001));
    expect(result.programs.map((program) => program.code), [
      'CSU',
      'CCS',
      'VIH',
    ]);
    expect(result.services.singleWhere((item) => item.code == 'A1').price, 15);
    expect(result.items.singleWhere((item) => item.code == '0176').price, 2.5);
    expect(
      result.services
          .singleWhere((item) => item.code == 'SHARED-CCS')
          .programCode,
      'CCS',
    );
    expect(
      result.items
          .singleWhere((item) => item.code == 'SHARED-ITEM-CCS')
          .programCode,
      'CCS',
    );
    expect(store.value, same(result));
    expect(
      store.value?.administrator.healthFacilityCode,
      result.administrator.healthFacilityCode,
    );
    expect(progress, [
      'Validating Claim Administrator…',
      'Checking for updates',
      'Programs…',
      'Diagnoses, Services, Items…',
    ]);
  });

  test('rejects a blank Claim Admin code before network calls', () async {
    final repository = ClaimSetupRepository(
      http,
      NativeGraphQLService(http),
      ClaimMasterDataStore(),
      cache,
    );
    await expectLater(
      repository.initialize('  '),
      throwsA(isA<FormatException>()),
    );
  });
}
