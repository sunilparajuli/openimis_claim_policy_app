import 'package:openimis_claim_policy_app/data/remote/api/providers/http_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'graphql_service_provider.g.dart';

@riverpod
NativeGraphQLService graphQLService(Ref ref) {
  final http = ref.watch(httpServiceProvider);
  return NativeGraphQLService(http);
}
