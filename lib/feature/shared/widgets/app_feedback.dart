import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';

import 'app_button.dart';

enum AppFeedbackType { success, error, warning, info }

/// Displays consistent result feedback in a centered, responsive modal.
Future<void> showAppFeedbackDialog({
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

  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: isDismissible,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 5, color: configuration.color),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: configuration.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            configuration.icon,
                            color: configuration.color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            title ?? configuration.title,
                            style: Theme.of(dialogContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isDismissible)
                          IconButton(
                            tooltip: MaterialLocalizations.of(
                              dialogContext,
                            ).closeButtonTooltip,
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          dialogContext,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        message,
                        style: Theme.of(dialogContext).textTheme.bodyMedium
                            ?.copyWith(
                              height: 1.45,
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (actionLabel != null && onAction != null) ...[
                      AppButton(
                        expanded: true,
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onAction();
                        },
                        label: Text(actionLabel),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        expanded: true,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.pop(dialogContext),
                        label: Text(context.tr('Cancel')),
                      ),
                    ] else
                      AppButton(
                        expanded: true,
                        onPressed: () => Navigator.pop(dialogContext),
                        label: Text(context.tr('OK')),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Compatibility alias for screens migrated from the former bottom sheet.
@Deprecated('Use showAppFeedbackDialog instead.')
Future<void> showAppFeedbackSheet({
  required BuildContext context,
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
  String? title,
  String? actionLabel,
  VoidCallback? onAction,
  bool isDismissible = true,
}) => showAppFeedbackDialog(
  context: context,
  message: message,
  type: type,
  title: title,
  actionLabel: actionLabel,
  onAction: onAction,
  isDismissible: isDismissible,
);

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
