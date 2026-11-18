import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/local/csu_master_data_cache.dart';
import 'package:openimis_claim_policy_app/data/remote/api/providers/http_service_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/repositories/csu_master_data_repository.dart';

final csuMasterDataRepositoryProvider = Provider<CsuMasterDataRepository>((
  ref,
) {
  return CsuMasterDataRepository(
    ref.watch(httpServiceProvider),
    CsuMasterDataCache(),
  );
});

final csuMasterDataProvider =
    AsyncNotifierProvider<CsuMasterDataController, CsuMasterDataSnapshot?>(
      CsuMasterDataController.new,
    );

class CsuMasterDataController extends AsyncNotifier<CsuMasterDataSnapshot?> {
  @override
  Future<CsuMasterDataSnapshot?> build() {
    return ref.read(csuMasterDataRepositoryProvider).loadCached();
  }

  Future<void> synchronize({ProgressCallback? onReceiveProgress}) async {
    final cached = state.value;
    if (cached == null) state = const AsyncLoading();
    try {
      final downloaded = await ref
          .read(csuMasterDataRepositoryProvider)
          .download(onReceiveProgress: onReceiveProgress);
      state = AsyncData(downloaded);
    } catch (error, stackTrace) {
      if (cached != null) {
        state = AsyncData(cached);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> reloadFromCache() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(csuMasterDataRepositoryProvider).loadCached(),
    );
  }
}
