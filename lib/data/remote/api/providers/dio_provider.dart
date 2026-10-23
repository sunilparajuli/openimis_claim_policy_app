import 'package:dio/dio.dart';
import 'package:openimis_claim_policy_app/data/app_providers/app_provider.dart';
import 'package:openimis_claim_policy_app/data/local/secure_storage_service.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/auth_interceptor.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/custom_log_interceptor.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/error_interceptor.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/openimis_mock_interceptor.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/retry_interceptor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// Provides a pre-configured [Dio] instance equipped with:
/// - Connect/Send/Receive timeouts (30s)
/// - Base URL & default headers
/// - [AuthInterceptor] for JWT Bearer injection & 401 token refresh replay
/// - [RetryInterceptor] for automatic retries with exponential backoff
/// - [ErrorInterceptor] for translating raw Dio errors into [ApiError]
/// - [CustomLoggerInterceptor] for debug logging
@riverpod
Dio dio(Ref ref) {
  final appConfig = ref.read(appProvider);
  final storage = ref.read(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: appConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (appConfig.apiKey.isNotEmpty) 'api-key': appConfig.apiKey,
      },
    ),
  );

  if (appConfig.demoMode) {
    dio.interceptors.add(OpenImisMockInterceptor(forceDemo: true));
  }

  dio.interceptors.add(AuthInterceptor(storage: storage, dio: dio));
  dio.interceptors.add(RetryInterceptor(dio: dio));
  dio.interceptors.add(ErrorInterceptor());
  dio.interceptors.add(CustomLoggerInterceptor());

  return dio;
}
