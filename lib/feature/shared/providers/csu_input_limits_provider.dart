import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/shared/models/csu_input_limits.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/csu_master_data_provider.dart';

final csuInputLimitsProvider = Provider<CsuInputLimits>((ref) {
  final snapshot = ref.watch(csuMasterDataProvider).value;
  if (snapshot == null) return const CsuInputLimits();
  return CsuInputLimits.fromMasterData(snapshot.data);
});
