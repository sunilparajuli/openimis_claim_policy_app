import 'package:dio/dio.dart';
import 'package:openimis_claim_policy_app/data/remote/api/error/api_error.dart';
import 'package:openimis_claim_policy_app/data/remote/api/error/api_error_handler.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/http_service.dart';

/// Concrete implementation of [HttpService] powered by Dio.
///
/// Features:
/// - Standard REST methods: GET, POST, PUT, PATCH, DELETE.
/// - File upload with multipart/form-data.
/// - File download with progress tracking.
/// - Cancellation support via [CancelToken].
/// - Automatic translation of errors to [ApiError].
class DioHttpService implements HttpService {
  final Dio _dio;

  DioHttpService(this._dio);

  /// Access underlying Dio instance if direct configuration is needed.
  Dio get dio => _dio;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _execute(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _execute(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _execute(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _execute(
      () => _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _execute(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileFieldName,
    String? fileName,
    Map<String, dynamic>? extraData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    return _execute(() async {
      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      final Map<String, dynamic> formMap = {
        fileFieldName: multipartFile,
        ...?extraData,
      };

      final formData = FormData.fromMap(formMap);

      return _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    });
  }

  @override
  Future<Response> download(
    String urlPath,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Options? options,
  }) {
    return _execute(
      () => _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: options,
      ),
    );
  }

  /// Wraps request execution and translates any DioException or unexpected error into [ApiError].
  Future<R> _execute<R>(Future<R> Function() request) async {
    try {
      return await request();
    } on DioException catch (e, stackTrace) {
      if (e.error is ApiError) {
        throw e.error as ApiError;
      }
      throw ApiErrorHandler.handleError(e, stackTrace);
    } catch (e, stackTrace) {
      throw ApiErrorHandler.handleError(e, stackTrace);
    }
  }
}
