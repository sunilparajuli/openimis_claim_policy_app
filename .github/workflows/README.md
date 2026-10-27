# Flutter CI

`ci.yml` runs on pushes to any branch, pull requests, version tags (`v*`), and
manual workflow requests.

## Checks and artifacts

- Ubuntu/Java 17: generate code, analyze, run tests with coverage, and build the
  optimized `prod` APK from `lib/main/main_prod.dart`.
- Every successful run uploads `openimis-claim-policy-app.apk` for 30 days.
- Pushing a tag such as `v1.0.0` also creates a GitHub Release and attaches the APK.

Download the APK and coverage from the workflow run's **Artifacts** section.

## Configuration

Set the optional repository variables `API_BASE_URL` and `DATA_MODE`, and secrets
`API_KEY` and `GOOGLE_MAPS_API_KEY`. Without them, CI uses the openIMIS demo API,
live data mode, an empty API key, and a placeholder Maps key. Both `.env` files
are generated only inside the runner.
Never commit your real environment files or generated environment credentials.

Commit all application source, new components, tests and `assets/` before pushing;
files that exist only locally are unavailable to the runners. Generated Dart code
is recreated with build_runner. The currently ignored `pubspec.lock` means CI
resolves versions from pubspec constraints; commit an application lockfile if you
want fully repeatable dependency resolution.

Analyzer errors and test/build failures fail CI. Existing analyzer warnings and
informational lints are displayed but are temporarily non-fatal. Remove
`--no-fatal-infos --no-fatal-warnings` when the existing lint backlog is resolved.
The workflow does not bypass test or build failures.

The current Gradle configuration signs release APKs with the debug key. They are
installable test releases, but not Play Store releases. Configure an upload
keystore through GitHub secrets before store publishing.

Action configuration references: [Flutter setup](https://github.com/subosito/flutter-action),
[artifact uploads](https://github.com/actions/upload-artifact).
