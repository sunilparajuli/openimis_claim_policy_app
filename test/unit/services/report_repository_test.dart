import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/dio_http_service.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';
import 'package:openimis_claim_policy_app/feature/policies/repositories/report_repository.dart';

void main() {
  late Dio dio;
  late ReportRepository repo;
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/'));
    final http = DioHttpService(dio);
    repo = ReportRepository(NativeGraphQLService(http), http);
  });
  tearDown(() => dio.close());

  test(
    'Cumulative report preserves renewed count and requested period',
    () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.data['variables'], {
              'officerCode': 'OFF-1',
              'from': '2026-01-01',
              'to': '2026-03-31',
            });
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'data': {
                    'new': {'totalCount': 10},
                    'renewed': {'totalCount': 7},
                    'expired': {'totalCount': 2},
                    'suspended': {'totalCount': 0},
                  },
                },
              ),
            );
          },
        ),
      );
      final data = await repo.indicators(
        'OFF-1',
        DateTime(2026),
        to: DateTime(2026, 3, 31),
      );
      expect(data['renewed'], 7);
      expect(data['expired'], 2);
    },
  );

  test(
    'Commission sends legacy filters and decodes nested JSON data',
    () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.path, 'rest/api/policy/commissions');
            expect(request.headers['api-version'], '3');
            expect(request.data, {
              'enrolment_officer_code': 'OFF-1',
              'month': 3,
              'year': 2026,
              'insrance_product_code': 'P1',
              'payer': '12',
              'mode': '0',
            });
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'errorOccured': false,
                  'data': '[{"amount":100,"commission":5}]',
                },
              ),
            );
          },
        ),
      );
      final rows = await repo.commission(
        officer: 'OFF-1',
        month: 3,
        year: 2026,
        product: 'P1',
        payer: '12',
        paid: false,
      );
      expect(rows.single['commission'], 5);
    },
  );

  test('Incomplete indicator response is not reported as zero', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.resolve(
            Response(requestOptions: request, data: {'data': {}}),
          );
        },
      ),
    );
    await expectLater(
      repo.indicators('OFF-1', DateTime(2026)),
      throwsFormatException,
    );
  });

  test('Commission business errors propagate', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.resolve(
            Response(
              requestOptions: request,
              data: {'errorOccured': 'true', 'messageValue': 'No permission'},
            ),
          );
        },
      ),
    );
    await expectLater(
      repo.commission(
        officer: 'OFF-1',
        month: 1,
        year: 2026,
        product: '',
        payer: '',
        paid: true,
      ),
      throwsFormatException,
    );
  });
}
