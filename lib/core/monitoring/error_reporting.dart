import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:openimis_claim_policy_app/feature/shared/app_flavour/app_config.dart';

enum AppWorkflow { shared, claims, policiesCsu, policiesHiv, enquire }

abstract final class ErrorReporting {
  static const dsn = String.fromEnvironment('GLITCHTIP_DSN');

  static Future<void> initialize({
    required AppConfig config,
    required FutureOr<void> Function() appRunner,
  }) async {
    if (!config.initializeCrashlytics || dsn.isEmpty) {
      await appRunner();
      return;
    }
    final package = await PackageInfo.fromPlatform();
    await SentryFlutter.init((options) {
      options
        ..dsn = dsn
        ..environment = config.environment.name
        ..release =
            '${package.packageName}@${package.version}+${package.buildNumber}'
        ..sendDefaultPii = false
        ..tracesSampleRate = 0
        ..enableAutoSessionTracking = true;
    }, appRunner: appRunner);
  }

  static Future<SentryId> capture(
    Object error,
    StackTrace stackTrace, {
    required AppWorkflow workflow,
  }) => Sentry.captureException(
    error,
    stackTrace: stackTrace,
    withScope: (scope) {
      scope
        ..setTag('app', 'csu-unified-mobile')
        ..setTag('workflow', workflow.name);
    },
  );

  static FutureOr<void> setWorkflow(AppWorkflow workflow) =>
      Sentry.configureScope((scope) {
        scope
          ..setTag('app', 'csu-unified-mobile')
          ..setTag('workflow', workflow.name);
      });
}
