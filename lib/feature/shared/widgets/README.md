# Shared UI components

Use these components in application screens. They share the app theme and keep
presentation separate from repositories, Riverpod state, navigation and validation.

```dart
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
```

## Component index

| Component | Usage |
| --- | --- |
| `AppTextField` | Text, password, search, numeric and multiline inputs |
| `AppDropdownField<T>` | Typed, validated selections |
| `AppAutocompleteField<T>` | Searchable typed selections for large catalogs |
| `AppDateField` | Read-only localized date input with a calendar picker |
| `AppButton` | Primary, filled, secondary and text actions; optional icon/loading |
| `AppAppBar` | Standard page title, actions, leading widget and optional tabs |
| `AppSliverAppBar` | Floating title inside a custom scroll view |
| `showAppBottomSheet<T>` | Responsive, keyboard-aware popup route returning a result |
| `AppSheetContent` | Scrollable sheet title, close button, content and actions |
| `AppLoadingIndicator` | Centered or inline progress spinner |
| `AppErrorMessage` | Inline error with live-region accessibility |
| `showAppFeedbackSheet` | Success, error, warning or information result modal |
| `AppEmptyState` | Empty message, icon and optional action |
| `AppStatusBadge` | Consistent neutral/info/success/warning/error status chip |
| `AppSectionHeader` | Accessible section title with optional subtitle/actions |
| `AppMoneySummaryRow` | Responsive label/value and subtotal layout |
| `AppFormCard` | Standard padded card for grouped form controls |
| `showAppConfirmationSheet` | Standard security/destructive confirmation sheet |
| `ErrorView` | API/Dio error page with an optional retry action |
| `Shimmer`, `ShimmerBox`, `ShimmerCircle` | Reusable skeleton building blocks |
| `ClaimListShimmer`, `InsureeVerificationShimmer` | Existing domain-specific skeleton compositions |

## Forms

Controllers and focus nodes belong to the screen: create them outside `build` and
dispose them there. Use either `controller` or `initialValue`, never both.
Validation and input formatting remain the caller's responsibility.

```dart
Form(
  key: formKey,
  child: AppTextField(
    controller: officerController,
    labelText: context.tr('Officer Code'),
    prefixIcon: const Icon(Icons.badge_outlined),
    textInputAction: TextInputAction.done,
    validator: (value) => value == null || value.trim().isEmpty
        ? context.tr('Enter an officer code') : null,
    onSubmitted: (_) => submit(),
  ),
)
```

For passwords use `obscureText: true` and a caller-controlled suffix visibility
button. For notes use `maxLines: 4`; for search use `onChanged`; for numeric input
use `keyboardType` and `inputFormatters`. The `decoration` parameter allows special
cases; explicit label/hint/helper/icon parameters override matching decoration
values. Other options include `enabled`, `readOnly`, `autovalidateMode`,
`autofillHints`, `onSaved`, `minLines`, `maxLength`, `onTap` and `focusNode`.

```dart
AppDropdownField<String>(
  labelText: context.tr('Currency'),
  value: currency,
  items: const [
    DropdownMenuItem(value: 'USD', child: Text('USD')),
    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
  ],
  onChanged: (value) {
    if (value != null) setState(() => currency = value);
  },
)
```

Use autocomplete for services, items, diagnoses, or any long server-backed
catalog. Provide a broader search string when users should be able to search by
both code and description:

```dart
AppAutocompleteField<MedicalService>(
  options: services,
  labelText: 'Medical Service',
  hintText: 'Type a service name or code',
  displayStringForOption: (service) => '${service.code} — ${service.name}',
  searchStringForOption: (service) => '${service.code} ${service.name}',
  onSelected: (service) => setState(() => selectedService = service),
)
```

Each non-null selection must match exactly one item. Use `enabled: false` or
`onChanged: null` to disable. Supports `validator`, `onSaved`, `hint`, `decoration`
and `autovalidateMode`. Update the parent state when a selection changes.

```dart
AppDateField(
  labelText: context.tr('Pick Date'),
  value: reportDate,
  firstDate: DateTime(1900),
  lastDate: DateTime.now(),
  onChanged: (date) => setState(() => reportDate = date),
)
```

Dates are formatted using the active locale. Keep non-null values within the
allowed bounds. `validator` receives a `DateTime?`; cancellation does not change
the value. For existing date buttons use `showAppDatePicker` or
`showAppDateRangePicker`, supplying `context`, bounds and an initial selection.
These intentionally retain Flutter's accessible calendar UI rather than embedding
a second calendar implementation in a sheet.

## Buttons

```dart
AppButton(
  label: Text(context.tr('Save')),
  icon: const Icon(Icons.save_outlined),
  isLoading: saving,
  expanded: true,
  onPressed: save,
)

AppButton(
  variant: AppButtonVariant.secondary,
  label: Text(context.tr('Cancel')),
  onPressed: () => Navigator.pop(context),
)
```

Provide exactly one of `label` or `child` (both accept widgets).
Variants map to elevated (`primary`, default), filled (`filled`), outlined
(`secondary`) and text (`text`) buttons. `isLoading` disables presses, displays a
spinner, and keeps the label visible; `loadingLabel` optionally replaces the text.
`onPressed: null` also disables the button. Prefer theme defaults; use `style` or
`AppButton.styleFrom` for genuine exceptions such as destructive actions.
Use ordinary `IconButton` for icon-only actions and provide a localized tooltip.

## Bottom sheets

```dart
final confirmed = await showAppBottomSheet<bool>(
  context: context,
  builder: (sheetContext) => AppSheetContent(
    title: Text(context.tr('Confirm')),
    content: Text(context.tr('Continue?')),
    actions: [
      AppButton(
        variant: AppButtonVariant.text,
        label: Text(context.tr('Cancel')),
        onPressed: () => Navigator.pop(sheetContext, false),
      ),
      AppButton(
        label: Text(context.tr('Confirm')),
        onPressed: () => Navigator.pop(sheetContext, true),
      ),
    ],
  ),
);
if (!context.mounted) return;
if (confirmed == true) performAction();
```

The launcher owns safe-area handling, root navigation, keyboard padding, rounded
corners, the drag handle and maximum height. Phones use full width; screens at
least 600 logical pixels wide use width minus 48 pixels. Dismissal returns null.
Use the builder's context to close the sheet. Do not add another drag handle or
duplicate keyboard padding.

Set `heightFactor` (for example, `0.62`) when a selection sheet should occupy a
stable portion of the available screen instead of sizing only to its content.

`AppSheetContent` scrolls its whole content and wraps actions on narrow screens.
Do not put an unbounded `Expanded` or `ListView` in its content. For complex
tabbed/detail sheets, supply a bounded custom layout to the same launcher; those
domain-specific layouts remain in their feature. For editable sheet state, use a
stateful widget or `StatefulBuilder`; creating a sheet does not copy parent state.

## App bars and tabs

```dart
Scaffold(
  appBar: AppAppBar(title: Text(context.tr('Settings'))),
  body: content,
)
```

`AppAppBar` accepts `leading`, `actions`, `bottom`, `centerTitle`,
`automaticallyImplyLeading`, `flexibleSpace`, color overrides and `elevation`.
For tabs, supply `bottom: TabBar(...)` inside a `DefaultTabController`; the app bar
includes the tab height. `AppSliverAppBar(title: Text(title), actions: actions)`
belongs in `CustomScrollView.slivers`.

## Loading, errors and empty results

Use a feedback sheet after an operation succeeds or fails. It provides the
standard icon, color, title, responsive width and acknowledgement button:

```dart
await showAppFeedbackSheet(
  context: context,
  type: AppFeedbackType.success,
  message: context.tr('Changes saved successfully'),
);
```

An error can offer a recovery action without building a custom sheet:

```dart
showAppFeedbackSheet(
  context: context,
  type: AppFeedbackType.error,
  message: errorMessage,
  actionLabel: context.tr('Retry'),
  onAction: retry,
);
```

Available types are `success`, `error`, `warning`, and `info`. Use
`AppErrorMessage` for errors that must remain visible inside a form. Existing
`showSnackBar(...)` calls are compatibility wrappers and now display this same
feedback sheet; new code should call `showAppFeedbackSheet` directly.

```dart
const AppLoadingIndicator()
const AppLoadingIndicator(size: 18, inline: true)
AppErrorMessage(message: context.tr('Unable to load report. Please try again.'))
AppEmptyState(message: context.tr('No data'))
ErrorView(error: error, onRetry: reload)
const ClaimListShimmer(count: 4)
const InsureeVerificationShimmer()
```

`AppLoadingIndicator` supports an accessible `label` and optional `color`.
`AppEmptyState` supports `icon` and `action`. Use a bounded area for full-page
states. Linear progress bars remain Flutter primitives for determinate/progress
strips. `ErrorView` retains its existing API-error mapping; its legacy error text
is English. Use localized `AppErrorMessage` where the caller owns translated text.

Build new skeletons by composing `Shimmer(child: ...)`,
`ShimmerBox(width: 120, height: 16)` and `ShimmerCircle(radius: 20)`.

## Theme, localization and ownership

- Global colors, fonts and input/button styling live in
  `../utils/styles/app_theme.dart`; change defaults there, not screen by screen.
- Components accept caller-provided text. Import
  `core/localization/app_localizations.dart` to use `context.tr(...)`, and add new
  English/French keys to the localization dictionary before shipping them.
- Monetary displays use `ref.watch(moneyFormatterProvider).format(amount)`;
  do not hard-code a currency symbol inside a generic widget.
- Keep API calls, permission requests, persistence and domain rules in existing
  screens/providers/repositories. The component library must not own them.
- Deployment defaults live in `assets/config/default.json` and are exposed by
  `appComponentConfigProvider`. Keep widget behavior and type-safe APIs in Dart;
  JSON is for configurable values, not arbitrary widget trees.
- Standardization covers application features under `lib/feature`.
  Layout primitives (`Row`, `Card`, `ListTile`, `Switch`, etc.) and unique domain
  compositions are not wrapped just for renaming.

## Compatibility and migration

Old imports remain usable: `CommonTextField` aliases `AppTextField`,
`PrimaryButton` adapts its string-label/icon-data API to `AppButton`, and
`SharedAppBar` / `SharedSliverAppBar` adapt string titles to the new app bars.
`ChatInputBox` in `common_text_field.dart` uses `AppTextField` internally.
Use the new barrel import for new screens; avoid new direct instances of
`TextField`, `TextFormField`, `DropdownButtonFormField`, text action buttons,
`AppBar`, `showDialog` or `showModalBottomSheet` in feature code.

## Verification

```bash
flutter analyze --no-pub lib/feature
flutter test --no-pub test/unit/screens/app_components_test.dart
flutter test --no-pub test/unit/screens/app_bottom_sheet_test.dart
flutter test --no-pub
```

Component tests cover form validation/submission, button loading, externally
updated dropdown selections, date cancellation and app-bar tab height. Sheet
tests cover responsive width, returned results, scrolling and keyboard insets.
