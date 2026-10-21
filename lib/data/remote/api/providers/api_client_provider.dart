import 'package:flutter_riverpod_template/data/app_providers/app_provider.dart';
import 'package:flutter_riverpod_template/data/remote/api/client/api_client.dart';
import 'package:flutter_riverpod_template/data/remote/api/providers/dio_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client_provider.g.dart';

@riverpod
ApiClient apiClient(Ref ref) {
  final dio = ref.watch(dioProvider);
  final provider = ref.read(appProvider);
  return ApiClient(dio, baseUrl: provider.baseUrl);
}
