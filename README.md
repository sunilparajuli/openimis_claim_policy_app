# openIMIS Claims & Policies Mobile App

Flutter mobile client for openIMIS claim and policy operations. The application
combines the operational scope of the openIMIS Java Claims and Policies Android
applications with shared navigation, authentication, localization, offline claim
storage, and reusable Material components.

## Supported workflows

- openIMIS login and optional biometric sign-in
- Claim Administrator setup and persisted facility context
- insuree enquiry
- claim entry with diagnoses, services, items, review, and submission
- Java-compatible offline claim storage and later upload
- family and dependent enrolment
- policy renewal
- feedback, indicators, reports, and officer commissions
- language, currency, permissions, biometric, and Claim Admin settings

The source of truth for server data is the configured openIMIS REST/FHIR and
GraphQL endpoints. Demo data is available only when explicitly enabled.

## Requirements

- Flutter `3.47.2` or a compatible stable version
- Dart version allowed by `pubspec.yaml`
- Android Studio/Xcode for native builds
- Java 17 for Android builds
- an openIMIS server for live mode

## First setup

```bash
git clone https://github.com/sunilparajuli/openimis_claim_policy_app.git
cd openimis_claim_policy_app
cp .env.example .env.dev
cp .env.example .env.prod
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Environment files and generated Dart files are intentionally ignored. Every new
checkout must create the environment files and run code generation.

## Configuration

Both `.env.dev` and `.env.prod` use the following keys:

```dotenv
API_BASE_URL=https://demo.openimis.org/
API_KEY=
ENVIRONMENT=dev
DATA_MODE=live
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

| Key | Purpose |
| --- | --- |
| `API_BASE_URL` | Base URL of the openIMIS deployment; keep the trailing slash |
| `API_KEY` | Optional deployment-specific API key |
| `ENVIRONMENT` | Build label, normally `dev` or `prod` |
| `DATA_MODE` | `live` for network data or `demo` for local demonstration responses |
| `GOOGLE_MAPS_API_KEY` | Native Maps key when map functionality is enabled |

Do not commit `.env.dev`, `.env.prod`, tokens, passwords, or production keys.
Envied obfuscation prevents casual string inspection but is not a secret vault;
server-side authorization must still protect every API.

After changing an environment file, regenerate its Dart source:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Use `flutter clean` only when native build output or generated environment values
remain stale. It is not required for normal Dart changes.

### Live data

Set `DATA_MODE=live` and point `API_BASE_URL` to the required openIMIS instance.
In live mode no demonstration interceptor is installed. Authentication, FHIR,
GraphQL, claims, insurees, reports, and master data requests go to that server.

```dotenv
API_BASE_URL=https://openimis.example.org/
API_KEY=
ENVIRONMENT=prod
DATA_MODE=live
GOOGLE_MAPS_API_KEY=...
```

The server must expose the endpoints used under `lib/data/remote` and permit the
mobile client to authenticate. Endpoint details are listed in
[`docs/api/API_LIST.md`](docs/api/API_LIST.md).

### Demo data

Set `DATA_MODE=demo` to use deterministic local responses implemented by
`OpenImisMockInterceptor`. Demo mode is for UI demonstrations and automated tests;
it must not be used to validate server integration or production behavior.

```dotenv
API_BASE_URL=https://demo.openimis.org/
API_KEY=
ENVIRONMENT=dev
DATA_MODE=demo
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

Demo mode is explicit. Changing the URL does not silently enable mock responses.
When adding a demo response, keep its contract identical to the corresponding
live endpoint and add a focused test.

### Current data ownership

| Area | Live mode | Demo mode |
| --- | --- | --- |
| Login | FHIR login endpoint | Local contract-compatible response |
| Claim Admin/master data | FHIR Practitioner/diagnosis plus GraphQL price lists | Local responses |
| Claim submission | FHIR Claim endpoint | Local accepted response |
| Offline claims | Device SQLite, then live upload | Device SQLite, then demo upload |
| Claims listing | No fabricated records; server listing adapter remains to be added | Demonstration records |
| Insuree enquiry | GraphQL | Local response |
| Indicators/commissions | GraphQL and commission REST API | Local responses |
| Family enrolment/feedback forms | In-memory UI workflow until the deployment API is connected | In-memory UI workflow |

This distinction is intentional: unfinished live integrations show an empty or
error state and never fall back silently to patient or policy sample data.

### JSON defaults

`assets/config/default.json` contains non-secret deployment/UI defaults such as
currency, supported languages, spacing, radii, and sheet height. It is loaded
through `appComponentConfigProvider`.

Use JSON for values that a deployment may configure. Do not define widget trees,
validation rules, credentials, API responses, or business workflows in JSON.
Those remain typed Dart code.

## Running the application

Development flavor:

```bash
flutter run --flavor dev -t lib/main/main_dev.dart
```

Production flavor:

```bash
flutter run --flavor prod -t lib/main/main_prod.dart
```

Android Studio run configuration:

- Dart entry point: `lib/main/main_dev.dart`
- Additional arguments: `--flavor dev`
- Select an Android emulator or iOS Simulator before running

The entry point must be selected from this project directory. Selecting a file
from another checkout causes Android Studio's “entrypoint isn't within the
project” error.

## Architecture

```text
lib/
├── core/                 configuration, localization, native bridges, auth
├── data/
│   ├── local/            secure persistence
│   └── remote/           Dio HTTP, GraphQL, interceptors, API contracts
├── feature/
│   ├── claims/           entry, listing, master data, offline queue
│   ├── insuree/          insuree enquiry
│   ├── policies/         enrolment, renewal, feedback, reports
│   ├── login/            authentication
│   ├── settings/         user-controlled configuration
│   └── shared/           routing, theme, session, reusable widgets
└── main/                 dev and prod entry points
```

Dependency direction should remain:

```text
UI → provider/notifier → repository → HTTP/GraphQL/SQLite service
```

Widgets must not build URLs, execute SQL, read secure storage directly, or parse
server responses. Repositories must not display sheets, snack bars, or navigate.

## Riverpod conventions

Riverpod owns application state and dependency injection. Use local widget state
only for short-lived presentation details such as the active form step, focus,
or a text controller.

### Reading and watching

- `ref.watch(provider)` rebuilds when state changes; use it in `build`.
- `ref.read(provider)` performs an action or obtains a stable dependency.
- `ref.listen(provider, ...)` handles one-time effects such as navigation or an
  error message.
- Never call network or database work directly during `build`.

### Provider placement

- Put feature providers beside their repository/model under that feature.
- Put cross-feature session/config providers under `feature/shared` or `core`.
- Providers should expose domain values, not prebuilt widgets.
- Keep providers alive only when the state is expensive or must survive
  navigation. Prefer automatic disposal for page-specific queries.

Example repository provider:

```dart
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(httpServiceProvider));
});
```

Example asynchronous controller:

```dart
@riverpod
class Families extends _$Families {
  @override
  Future<List<Family>> build() {
    return ref.watch(familyRepositoryProvider).list();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

Code annotated with `@riverpod`, `@freezed`, Retrofit, Envied, or AutoRoute
requires generated companion files. Never edit `*.g.dart`, `*.freezed.dart`, or
`*.gr.dart` manually. Regenerate them with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Reusable UI components

Import the shared barrel rather than individual implementation files:

```dart
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
```

Use these components for new application screens:

| Need | Component |
| --- | --- |
| Text/password/number input | `AppTextField` |
| Small typed selection | `AppDropdownField<T>` |
| Searchable diagnosis/service/item selection | `AppAutocompleteField<T>` |
| Date input | `AppDateField` |
| Primary, secondary, text, or loading action | `AppButton` |
| Page title and actions | `AppAppBar` |
| Responsive popup | `showAppBottomSheet<T>` with `AppSheetContent` |
| Confirmation/security prompt | `showAppConfirmationSheet` |
| Grouped fields | `AppFormCard` |
| Section title | `AppSectionHeader` |
| Status | `AppStatusBadge` |
| Currency/subtotal line | `AppMoneySummaryRow` |
| Empty/loading/error feedback | `AppEmptyState`, `AppLoadingIndicator`, `AppErrorMessage` |

Example form:

```dart
AppFormCard(
  title: context.tr('Claim Details'),
  child: Column(
    children: [
      AppTextField(
        controller: claimCodeController,
        labelText: context.tr('Claim Code'),
        validator: requiredValue,
      ),
      const SizedBox(height: 12),
      AppAutocompleteField<Diagnosis>(
        options: diagnoses,
        labelText: context.tr('Diagnosis'),
        displayStringForOption: (value) => '${value.code} — ${value.name}',
        searchStringForOption: (value) => '${value.code} ${value.name}',
        onSelected: selectDiagnosis,
      ),
    ],
  ),
)
```

Example confirmation:

```dart
final confirmed = await showAppConfirmationSheet(
  context: context,
  title: context.tr('Clear Claim Administrator?'),
  message: context.tr('The saved Claim Administrator code will be removed.'),
  confirmLabel: context.tr('Clear'),
  destructive: true,
);
if (confirmed == true) await clearClaimAdministrator();
```

Rules for reusable components:

- Add generic behavior to `feature/shared/widgets`, not a domain-specific widget.
- Keep labels supplied by the caller and localized with `context.tr(...)`.
- Use the theme and `MoneyFormatter`; do not hard-code fonts or currency symbols.
- Components own layout and interaction presentation, not API or database work.
- Add widget tests for validation, overflow, loading, keyboard, and returned values.
- Use a normal domain widget when a composition is unique to one workflow.

The complete component API and more examples are in
[`lib/feature/shared/widgets/README.md`](lib/feature/shared/widgets/README.md).

## Offline claims

`ClaimSqliteDatabase` mirrors the Java Claims app tables:

- `tblClaimDetails`
- `tblClaimItems`
- `tblClaimServices`
- `tblClaimUploadStatus`

Upload status is append-only history using Java status names such as `Accepted`,
`Rejected`, and `Error`. A claim with no non-error status remains pending. SQLite
indexes support claim-code lookup, child records, status history, and fast pending
counts. Schema upgrades must increment `dbVersion` and preserve existing claims.

Do not place access tokens or passwords in SQLite. Authentication material belongs
in `flutter_secure_storage`.

## Localization and naming

The English claim labels follow the Java Claims application, including
`Insurance No`, `Health Facility Code`, `Claim Admin`, `Diagnosis`, `Services`,
`Items`, `Post Claim`, and `Upload Claims`.

When adding a label:

1. Add the English/French mapping in `core/localization`.
2. Render it through `context.tr(...)` or `AppLocalizations`.
3. Update localization tests.
4. Do not introduce a second name for an existing Java/OpenIMIS concept.

## Adding a feature

1. Create a folder under `lib/feature/<feature>`.
2. Define typed domain models.
3. Add a repository that depends on the shared HTTP, GraphQL, or local service.
4. Expose repository/state through Riverpod.
5. Build screens from shared components.
6. Add localization keys and tests.
7. Run generation, formatting, analysis, and tests.

## Testing and quality checks

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze --no-pub
flutter test --no-pub
```

Focused component tests:

```bash
flutter test --no-pub test/unit/screens/app_components_test.dart
flutter test --no-pub test/unit/screens/app_bottom_sheet_test.dart
```

## Building and releases

Build both the development debug APK and production release APK:

```bash
./scripts/build_android_apks.sh
```

Build only one variant:

```bash
./scripts/build_android_apks.sh debug
./scripts/build_android_apks.sh release
```

The versioned APKs are copied to `outputs/android/`. The script uses `.env.dev`
for the debug flavor and `.env.prod` for the release flavor. Set `FLUTTER_BIN`
when Flutter is not available on `PATH`:

```bash
FLUTTER_BIN=/path/to/flutter/bin/flutter ./scripts/build_android_apks.sh
```

To force a clean build:

```bash
CLEAN_BUILD=1 ./scripts/build_android_apks.sh
```

Release builds are split by Android CPU architecture, so users download only
the native libraries their device needs. Use `arm64-v8a` for most current Android
phones, `armeabi-v7a` for older 32-bit phones, and `x86_64` for emulators.

Equivalent direct production command:

```bash
flutter build apk --release --split-per-abi --flavor prod -t lib/main/main_prod.dart
```

`.github/workflows/ci.yml` runs generation, analysis, tests, and the production APK
build on pushes and pull requests. A tag such as `v1.0.0` publishes the three
architecture-specific APKs to a GitHub Release.

The current Android release build uses debug signing for installable test APKs.
Configure a protected upload keystore and GitHub secrets before Play Store use.

## Security checklist

- Never commit environment files, credentials, tokens, or keystores.
- Keep production in `DATA_MODE=live`.
- Do not log credentials, bearer tokens, biometric results, or patient data.
- Store session and Claim Admin secrets through `SecureStorageService`.
- Validate authorization on the server; hiding a screen is not authorization.
- Review Android/iOS permissions whenever camera, photo, location, or biometric
  behavior changes.

## Related projects

- [openIMIS Claims Android app](https://github.com/openimis/claims_android_app_java)
- [openIMIS Policies Android app](https://github.com/openimis/policies_android_app_java)
- [openIMIS](https://www.openimis.org/)
