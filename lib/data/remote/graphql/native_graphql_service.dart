import 'package:dio/dio.dart';
import 'package:flutter_riverpod_template/data/remote/api/error/api_error.dart';
import 'package:flutter_riverpod_template/data/remote/api/service/http_service.dart';

/// Lightweight native GraphQL client implementation built directly on top of [HttpService].
///
/// Executes queries and mutations over standard HTTP POST to `/api/graphql` without
/// requiring external third-party GraphQL client libraries.
class NativeGraphQLService {
  final HttpService _httpService;
  final String _endpoint;

  NativeGraphQLService(
    this._httpService, {
    String endpoint = 'api/graphql',
  }) : _endpoint = endpoint;

  /// Executes a GraphQL query against the backend.
  Future<Map<String, dynamic>> query(
    String query, {
    Map<String, dynamic>? variables,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _execute(
      query: query,
      variables: variables,
      cancelToken: cancelToken,
      options: options,
    );
  }

  /// Executes a GraphQL mutation against the backend.
  Future<Map<String, dynamic>> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _execute(
      query: mutation,
      variables: variables,
      cancelToken: cancelToken,
      options: options,
    );
  }

  Future<Map<String, dynamic>> _execute({
    required String query,
    Map<String, dynamic>? variables,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    final payload = {
      'query': query,
      if (variables != null && variables.isNotEmpty) 'variables': variables,
    };

    final response = await _httpService.post<Map<String, dynamic>>(
      _endpoint,
      data: payload,
      cancelToken: cancelToken,
      options: options,
    );

    final body = response.data;
    if (body == null) {
      throw const ApiError(
        type: ApiErrorType.server,
        message: 'Empty GraphQL response from server',
      );
    }

    // Inspect if GraphQL errors were returned in the payload
    if (body.containsKey('errors') && body['errors'] != null) {
      final errorsList = body['errors'] as List;
      if (errorsList.isNotEmpty) {
        final firstError = errorsList.first;
        final errorMessage = firstError is Map
            ? (firstError['message'] as String? ?? 'GraphQL execution error')
            : firstError.toString();

        throw ApiError(
          type: ApiErrorType.client,
          message: errorMessage,
          error: errorsList,
        );
      }
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }
}
