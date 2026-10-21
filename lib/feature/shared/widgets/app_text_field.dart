import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme-driven text input. The caller owns controllers, focus and validation.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onSaved,
    this.onTap,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autovalidateMode,
    this.style,
  }) : assert(controller == null || initialValue == null);

  final TextEditingController? controller;
  final String? initialValue, labelText, hintText, helperText;
  final Widget? prefixIcon, suffixIcon;
  final InputDecoration? decoration;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged, onSubmitted;
  final FormFieldSetter<String>? onSaved;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool obscureText, enabled, readOnly, autofocus;
  final int? maxLines, minLines, maxLength;
  final AutovalidateMode? autovalidateMode;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: initialValue,
    focusNode: focusNode,
    validator: validator,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    onSaved: onSaved,
    onTap: onTap,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    textCapitalization: textCapitalization,
    inputFormatters: inputFormatters,
    autofillHints: autofillHints,
    obscureText: obscureText,
    enabled: enabled,
    readOnly: readOnly,
    autofocus: autofocus,
    maxLines: maxLines,
    minLines: minLines,
    maxLength: maxLength,
    autovalidateMode: autovalidateMode,
    style: style,
    decoration: (decoration ?? const InputDecoration()).copyWith(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    ),
  );
}
