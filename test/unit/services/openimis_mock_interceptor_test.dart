import 'package:dio/dio.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/openimis_mock_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenImisMockInterceptor Tests', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.github.com/'));
      dio.interceptors.add(OpenImisMockInterceptor(forceDemo: true));
    });

    test(
      'Intercepts FHIR R4 Claim POST and returns 201 Created without calling remote host',
      () async {
        final response = await dio.post<Map<String, dynamic>>(
          'api/api_fhir_r4/Claim/',
          data: {'resourceType': 'Claim', 'id': 'CLM-12345'},
        );

        expect(response.statusCode, 201);
        expect(response.data?['resourceType'], 'ClaimResponse');
        expect(response.data?['outcome'], 'complete');
      },
    );

    test('Intercepts FHIR R4 Claim GET and returns 200 Bundle', () async {
      final response = await dio.get<Map<String, dynamic>>(
        'api/api_fhir_r4/Claim/',
      );

      expect(response.statusCode, 200);
      expect(response.data?['resourceType'], 'Bundle');
    });

    test(
      'Intercepts GraphQL indicators query and returns 200 with dataset',
      () async {
        final response = await dio.post<Map<String, dynamic>>(
          'api/graphql',
          data: {'query': 'query { active { totalCount } }'},
        );

        expect(response.statusCode, 200);
        expect(response.data?['data']?['active']?['totalCount'], 1248);
      },
    );

    test('Intercepts policy commissions and returns 200 list', () async {
      final response = await dio.get<List<dynamic>>(
        'rest/api/policy/commissions',
      );

      expect(response.statusCode, 200);
      expect(response.data?.isNotEmpty, true);
    });
  });
}
