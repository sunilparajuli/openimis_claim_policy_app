import 'package:openimis_claim_policy_app/data/remote/api/providers/dio_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/dio_http_service.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/http_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_service_provider.g.dart';

/// Exposes the global [HttpService] implementation for making REST API calls.
@riverpod
HttpService httpService(Ref ref) {
  final dio = ref.watch(dioProvider);
  return DioHttpService(dio);
}
