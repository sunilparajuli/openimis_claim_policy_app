import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';

import 'app_bottom_sheet.dart';
import 'app_button.dart';

enum AppFeedbackType { success, error, warning, info }

/// Displays consistent result feedback in the app's modal bottom-sheet style.
Future<void> showAppFeedbackSheet({
  required BuildContext context,
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
  String? title,
  String? actionLabel,
  VoidCallback? onAction,
  bool isDismissible = true,
}) async {
  final configuration = switch (type) {
    AppFeedbackType.success => (
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF2E7D32),
      title: context.tr('Success'),
    ),
    AppFeedbackType.error => (
      icon: Icons.error_rounded,
      color: Theme.of(context).colorScheme.error,
      title: context.tr('Error'),
    ),
    AppFeedbackType.warning => (
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFED6C02),
      title: context.tr('Warning'),
    ),
    AppFeedbackType.info => (
      icon: Icons.info_rounded,
      color: Theme.of(context).colorScheme.primary,
      title: context.tr('Information'),
    ),
  };

  await showAppBottomSheet<void>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    builder: (sheetContext) => AppSheetContent(
      icon: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: configuration.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(configuration.icon, color: configuration.color, size: 42),
      ),
      title: Text(title ?? configuration.title),
      content: Text(message),
      actions: [
        if (actionLabel != null && onAction != null)
          AppButton(
            variant: AppButtonVariant.secondary,
            onPressed: () {
              Navigator.pop(sheetContext);
              onAction();
            },
            label: Text(actionLabel),
          ),
        AppButton(
          onPressed: () => Navigator.pop(sheetContext),
          label: Text(context.tr('OK')),
        ),
      ],
    ),
  );
}

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.inline = false,
    this.label,
    this.color,
  });
  final double size;
  final bool inline;
  final String? label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color:
            color ?? (inline ? DefaultTextStyle.of(context).style.color : null),
        semanticsLabel: label,
      ),
    );
    return inline ? spinner : Center(child: spinner);
  }
}

/// Localized message is supplied by the caller. Suitable for inline failures.
class AppErrorMessage extends StatelessWidget {
  const AppErrorMessage({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.description,
    this.iconSize = 48,
  });
  final String message;
  final IconData icon;
  final Widget? action;
  final String? description;
  final double iconSize;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
