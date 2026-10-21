import 'package:dio/dio.dart';
import 'package:flutter_riverpod_template/data/app_providers/app_provider.dart';
import 'package:flutter_riverpod_template/data/local/secure_storage_service.dart';
import 'package:flutter_riverpod_template/data/remote/api/client/auth_interceptor.dart';
import 'package:flutter_riverpod_template/data/remote/api/client/custom_log_interceptor.dart';
import 'package:flutter_riverpod_template/data/remote/api/client/error_interceptor.dart';
import 'package:flutter_riverpod_template/data/remote/api/client/retry_interceptor.dart';
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

  // 1. Auth interceptor - attaches token & auto-refreshes on 401
  dio.interceptors.add(AuthInterceptor(storage: storage, dio: dio));

  // 2. Retry interceptor - retries on transient connection issues and 5xx
  dio.interceptors.add(RetryInterceptor(dio: dio));

  // 3. Error interceptor - handles and logs API errors
  dio.interceptors.add(ErrorInterceptor());

  // 4. Logger interceptor - logs requests & responses
  dio.interceptors.add(CustomLoggerInterceptor());

  return dio;
}
