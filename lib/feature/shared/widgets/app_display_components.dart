import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_bottom_sheet.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_button.dart';

enum AppStatusTone { neutral, info, success, warning, danger }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      AppStatusTone.neutral => scheme.onSurfaceVariant,
      AppStatusTone.info => scheme.primary,
      AppStatusTone.success => Colors.green.shade700,
      AppStatusTone.warning => Colors.orange.shade800,
      AppStatusTone.danger => scheme.error,
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 8),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    ),
  );
}

class AppMoneySummaryRow extends StatelessWidget {
  const AppMoneySummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.icon,
  });

  final String label;
  final String value;
  final bool emphasized;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 16,
    runSpacing: 6,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
      Text(
        value,
        style:
            (emphasized
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
                  color: emphasized
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: FontWeight.w700,
                ),
      ),
    ],
  );
}

class AppFormCard extends StatelessWidget {
  const AppFormCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Card(
    margin: margin,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    ),
  );
}

Future<bool?> showAppConfirmationSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  IconData icon = Icons.security_rounded,
  bool destructive = false,
  double heightFactor = 0.5,
}) => showAppBottomSheet<bool>(
  context: context,
  heightFactor: heightFactor,
  builder: (sheetContext) {
    final scheme = Theme.of(sheetContext).colorScheme;
    final accent = destructive ? scheme.error : scheme.primary;
    return AppSheetContent(
      title: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        AppButton(
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(sheetContext, false),
          label: Text(cancelLabel),
        ),
        AppButton(
          onPressed: () => Navigator.pop(sheetContext, true),
          style: destructive
              ? AppButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          label: Text(confirmLabel),
        ),
      ],
    );
  },
);
