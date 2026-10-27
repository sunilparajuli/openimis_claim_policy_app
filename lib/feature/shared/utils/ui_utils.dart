import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_feedback.dart';

enum SnackBarType { success, error, info, warning }

Future<void> showSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
}) {
  return showAppFeedbackDialog(
    context: context,
    message: message,
    type: switch (type) {
      SnackBarType.success => AppFeedbackType.success,
      SnackBarType.error => AppFeedbackType.error,
      SnackBarType.warning => AppFeedbackType.warning,
      SnackBarType.info => AppFeedbackType.info,
    },
  );
}
