import 'package:dio/dio.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/openimis_mock_interceptor.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/dio_http_service.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_master_data.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_setup_repository.dart';
import 'package:openimis_claim_policy_app/feature/login/models/login_request_model.dart';
import 'package:openimis_claim_policy_app/feature/login/repositories/openimis_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DioHttpService http;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com/'));
    dio.interceptors.add(OpenImisMockInterceptor(forceDemo: true));
    http = DioHttpService(dio);
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
    );
    final result = await repository.initialize(
      'RHOS0011',
      onProgress: progress.add,
    );

    expect(result.administrator.code, 'RHOS0011');
    expect(result.administrator.healthFacilityCode, 'RAHOS001');
    expect(result.diagnoses, isNotEmpty);
    expect(result.services.singleWhere((item) => item.code == 'A1').price, 15);
    expect(result.items.singleWhere((item) => item.code == '0176').price, 2.5);
    expect(store.value, same(result));
    expect(progress, [
      'Validating Claim Administrator…',
      'Checking for updates',
      'Diagnoses, Services, Items…',
    ]);
  });

  test('rejects a blank Claim Admin code before network calls', () async {
    final repository = ClaimSetupRepository(
      http,
      NativeGraphQLService(http),
      ClaimMasterDataStore(),
    );
    await expectLater(
      repository.initialize('  '),
      throwsA(isA<FormatException>()),
    );
  });
}
