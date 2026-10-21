import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_text_field.dart';

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
);

Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showDateRangePicker(
  context: context,
  initialDateRange: initialDateRange,
  firstDate: firstDate,
  lastDate: lastDate,
);

/// Controlled, validated date input; cancellation leaves the value unchanged.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.enabled = true,
    this.validator,
  });
  final String labelText;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate, lastDate;
  final bool enabled;
  final String? Function(DateTime?)? validator;
  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? ''
        : DateFormat.yMd(
            Localizations.localeOf(context).toString(),
          ).format(value!);
    return AppTextField(
      key: ValueKey(formatted),
      initialValue: formatted,
      labelText: labelText,
      readOnly: true,
      enabled: enabled,
      suffixIcon: const Icon(Icons.calendar_today_outlined),
      validator: (_) => validator?.call(value),
      onTap: () async {
        final today = DateUtils.dateOnly(DateTime.now());
        final initial =
            value ??
            (today.isBefore(firstDate)
                ? firstDate
                : today.isAfter(lastDate)
                ? lastDate
                : today);
        final selected = await showAppDatePicker(
          context: context,
          initialDate: initial,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (selected != null && context.mounted) onChanged(selected);
      },
    );
  }
}
