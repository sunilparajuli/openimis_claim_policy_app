import 'package:dio/dio.dart';
import 'package:flutter_riverpod_template/data/remote/api/client/retry_interceptor.dart';
import 'package:flutter_riverpod_template/data/remote/api/error/api_error.dart';
import 'package:flutter_riverpod_template/data/remote/api/service/dio_http_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioHttpService Tests', () {
    late Dio dio;
    late DioHttpService httpService;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      httpService = DioHttpService(dio);
    });

    test('GET request successfully returns data', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/items' && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {'id': 1, 'name': 'Item 1'},
                  ],
                ),
              );
            }
            handler.next(options);
          },
        ),
      );

      final response = await httpService.get<List<dynamic>>('/items');

      expect(response.statusCode, 200);
      expect(response.data?.first['name'], 'Item 1');
    });

    test('POST request successfully sends payload and receives data', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/items' && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {'id': 2, ...options.data as Map<String, dynamic>},
                ),
              );
            }
            handler.next(options);
          },
        ),
      );

      final response = await httpService.post<Map<String, dynamic>>(
        '/items',
        data: {'name': 'New Item'},
      );

      expect(response.statusCode, 201);
      expect(response.data?['name'], 'New Item');
      expect(response.data?['id'], 2);
    });

    test('PUT request successfully updates data', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/items/1' && options.method == 'PUT') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'id': 1, 'name': 'Updated Item'},
                ),
              );
            }
            handler.next(options);
          },
        ),
      );

      final response = await httpService.put<Map<String, dynamic>>(
        '/items/1',
        data: {'name': 'Updated Item'},
      );

      expect(response.statusCode, 200);
      expect(response.data?['name'], 'Updated Item');
    });

    test('PATCH request successfully applies partial update', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/items/1' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'id': 1, 'status': 'active'},
                ),
              );
            }
            handler.next(options);
          },
        ),
      );

      final response = await httpService.patch<Map<String, dynamic>>(
        '/items/1',
        data: {'status': 'active'},
      );

      expect(response.statusCode, 200);
      expect(response.data?['status'], 'active');
    });

    test('DELETE request successfully removes resource', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/items/1' && options.method == 'DELETE') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 204,
                  data: null,
                ),
              );
            }
            handler.next(options);
          },
        ),
      );

      final response = await httpService.delete('/items/1');

      expect(response.statusCode, 204);
    });

    test('Translates 404 response to ApiError.notFound', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'message': 'Not Found'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      expect(
        () => httpService.get('/unknown'),
        throwsA(
          isA<ApiError>()
              .having((e) => e.type, 'type', ApiErrorType.notFound)
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('Translates connection timeout to ApiError.timeout', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
              ),
            );
          },
        ),
      );

      expect(
        () => httpService.get('/slow'),
        throwsA(
          isA<ApiError>()
              .having((e) => e.type, 'type', ApiErrorType.timeout),
        ),
      );
    });
  });

  group('RetryInterceptor Tests', () {
    test('Retries failed request up to maxRetries on connection error', () async {
      final dio = Dio();

      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 2,
          retryDelays: const [Duration(milliseconds: 10), Duration(milliseconds: 20)],
        ),
      );

      final mockAdapter = _MockFailThenSucceedAdapter(failuresBeforeSuccess: 2);
      dio.httpClientAdapter = mockAdapter;

      final response = await dio.get('/retry-test');
      expect(response.statusCode, 200);
      expect(response.data['recovered'], true);
      expect(mockAdapter.attempts, 3); // initial + 2 retries
    });

    test('Does not retry when no_retry extra option is set', () async {
      final dio = Dio();

      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: 3,
          retryDelays: const [Duration(milliseconds: 10)],
        ),
      );

      final mockAdapter = _MockFailThenSucceedAdapter(failuresBeforeSuccess: 5);
      dio.httpClientAdapter = mockAdapter;

      try {
        await dio.get(
          '/no-retry',
          options: Options(extra: {'no_retry': true}),
        );
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<DioException>());
        expect(mockAdapter.attempts, 1); // No retries attempted
      }
    });
  });
}

class _MockFailThenSucceedAdapter implements HttpClientAdapter {
  final int failuresBeforeSuccess;
  int attempts = 0;

  _MockFailThenSucceedAdapter({required this.failuresBeforeSuccess});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    attempts++;
    if (attempts <= failuresBeforeSuccess) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Simulated network connection drop',
      );
    }
    return ResponseBody.fromString(
      '{"recovered": true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

