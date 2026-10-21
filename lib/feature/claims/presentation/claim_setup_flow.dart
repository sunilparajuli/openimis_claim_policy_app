import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_master_data.dart';
import 'package:flutter_riverpod_template/feature/claims/presentation/claim_setup_sheet.dart';
import 'package:flutter_riverpod_template/feature/shared/providers/user_session_provider.dart';
import 'package:flutter_riverpod_template/feature/shared/widgets/app_widgets.dart';

/// Ensures Claims-specific master data is configured without coupling it to
/// the shared openIMIS login used by the Policies application.
Future<bool> ensureClaimAdministratorConfigured(
  BuildContext context,
  WidgetRef ref,
) async {
  final session = ref.read(userSessionProvider).value;
  if (session?.claimAdminCode?.isNotEmpty == true) return true;

  final result = await showAppBottomSheet<ClaimMasterData>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => const ClaimSetupSheet(),
  );
  if (result == null || !context.mounted) return false;

  final admin = result.administrator;
  await ref
      .read(userSessionProvider.notifier)
      .configureClaimAdministrator(
        code: admin.code,
        name: admin.displayName,
        healthFacilityCode: admin.healthFacilityCode,
        healthFacilityName: admin.healthFacilityName,
      );
  return context.mounted;
}
