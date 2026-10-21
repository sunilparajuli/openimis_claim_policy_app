import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// An interceptor that automatically retries failed requests due to transient
/// network errors or server issues (5xx) with exponential backoff.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;

    // Do not retry if explicit opt-out is requested
    if (requestOptions.extra['no_retry'] == true) {
      return handler.next(err);
    }

    // Do not retry if request was deliberately cancelled
    if (err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }

    // Do not retry non-idempotent streaming payloads
    if (requestOptions.data is Stream) {
      return handler.next(err);
    }

    final currentRetry = (requestOptions.extra['retry_count'] as int?) ?? 0;

    if (_shouldRetry(err) && currentRetry < maxRetries) {
      final nextRetry = currentRetry + 1;
      requestOptions.extra['retry_count'] = nextRetry;

      final delay = nextRetry <= retryDelays.length
          ? retryDelays[nextRetry - 1]
          : retryDelays.last * (nextRetry - retryDelays.length + 1);

      if (kDebugMode) {
        debugPrint(
          '🔄 [RetryInterceptor] Retrying request ($nextRetry/$maxRetries) in ${delay.inSeconds}s: ${requestOptions.uri}',
        );
      }

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  /// Determines if the error is transient and eligible for retry.
  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        // Retry transient server errors (500, 502, 503, 504)
        return statusCode != null && (statusCode >= 500 && statusCode < 600);
      default:
        return false;
    }
  }
}
