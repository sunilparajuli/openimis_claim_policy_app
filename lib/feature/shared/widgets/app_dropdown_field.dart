import 'package:flutter/material.dart';

/// Typed selection input sharing the app's form decoration and validation.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.labelText,
    this.hint,
    this.decoration,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.isExpanded = true,
    this.enabled = true,
  });
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? labelText;
  final Widget? hint;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final bool isExpanded, enabled;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    items: items,
    onChanged: enabled ? onChanged : null,
    isExpanded: isExpanded,
    hint: hint,
    validator: validator,
    onSaved: onSaved,
    autovalidateMode: autovalidateMode,
    decoration: (decoration ?? const InputDecoration()).copyWith(
      labelText: labelText,
    ),
  );
}
