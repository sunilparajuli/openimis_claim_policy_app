import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';

/// A searchable, typed selection field using the app's standard form styling.
///
/// Users can type any part of an option's searchable text and then select a
/// matching result. A typed value is not considered selected until the user
/// chooses an option from the results.
class AppAutocompleteField<T extends Object> extends StatelessWidget {
  const AppAutocompleteField({
    required this.options,
    required this.displayStringForOption,
    required this.onSelected,
    super.key,
    this.searchStringForOption,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.prefixIcon,
    this.noResultsText = 'No matching results',
    this.enabled = true,
    this.onCleared,
  });

  final Iterable<T> options;
  final String Function(T option) displayStringForOption;
  final String Function(T option)? searchStringForOption;
  final AutocompleteOnSelected<T> onSelected;
  final String? labelText;
  final String? hintText;
  final T? initialValue;
  final Widget? prefixIcon;
  final String noResultsText;
  final bool enabled;
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    final values = options.toList(growable: false);

    return Autocomplete<T>(
      initialValue: initialValue == null
          ? null
          : TextEditingValue(text: displayStringForOption(initialValue as T)),
      displayStringForOption: displayStringForOption,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return values;
        return values.where((option) {
          final searchable =
              searchStringForOption?.call(option) ??
              displayStringForOption(option);
          return searchable.toLowerCase().contains(query);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              prefixIcon: prefixIcon,
              suffixIcon: onCleared != null && value.text.isNotEmpty
                  ? IconButton(
                      tooltip: context.tr('Clear selection'),
                      onPressed: () {
                        controller.clear();
                        onCleared?.call();
                        focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : const Icon(Icons.arrow_drop_down),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, matches) {
        final results = matches.toList(growable: false);
        final availableWidth = MediaQuery.sizeOf(context).width - 32;
        final menuWidth = availableWidth > 520.0 ? 520.0 : availableWidth;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: menuWidth,
                maxWidth: menuWidth,
                maxHeight: 280,
              ),
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(noResultsText),
                    )
                  : Scrollbar(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final option = results[index];
                          return ListTile(
                            dense: true,
                            title: Text(displayStringForOption(option)),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
