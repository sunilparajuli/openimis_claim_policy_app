import 'package:flutter/material.dart';
import 'app_button.dart';

/// Compatibility adapter. New screens should use AppButton.
@Deprecated('Use AppButton')
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading, expanded;
  @override
  Widget build(BuildContext context) => AppButton(
    onPressed: onPressed,
    label: Text(label),
    icon: icon == null ? null : Icon(icon),
    isLoading: isLoading,
    expanded: expanded,
  );
}
