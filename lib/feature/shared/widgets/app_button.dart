import 'package:flutter/material.dart';
import 'app_feedback.dart';

enum AppButtonVariant { primary, filled, secondary, text }

/// A single action API for filled, outlined and text buttons.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expanded = false,
    this.style,
    this.loadingLabel,
  }) : assert(
         (child == null) != (label == null),
         'Provide either child or label',
       );
  final VoidCallback? onPressed;
  final Widget? child, label, icon;
  final AppButtonVariant variant;
  final bool isLoading, expanded;
  final ButtonStyle? style;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final text = child ?? label!;
    final contents = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const AppLoadingIndicator(size: 18, inline: true)
        else ...[
          ?icon,
        ],
        if (isLoading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: loadingLabel != null && isLoading ? Text(loadingLabel!) : text,
        ),
      ],
    );
    final callback = isLoading ? null : onPressed;
    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: callback,
        style: style,
        child: contents,
      ),
      AppButtonVariant.filled => FilledButton(
        onPressed: callback,
        style: style,
        child: contents,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        style: style,
        child: contents,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: callback,
        style: style,
        child: contents,
      ),
    };
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  /// Per-action exceptions (e.g. destructive actions or provider branding).
  /// Ordinary buttons should inherit appTheme instead.
  static ButtonStyle styleFrom({
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    OutlinedBorder? shape,
    BorderSide? side,
    TextStyle? textStyle,
    Size? minimumSize,
    Size? fixedSize,
    double? elevation,
  }) => TextButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    padding: padding,
    shape: shape,
    side: side,
    textStyle: textStyle,
    minimumSize: minimumSize,
    fixedSize: fixedSize,
    elevation: elevation,
  );
}
