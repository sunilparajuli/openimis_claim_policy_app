import 'package:flutter/widgets.dart';
import 'package:openimis_claim_policy_app/core/config/env.dart';
import 'package:openimis_claim_policy_app/feature/shared/app_flavour/app_config.dart';
import 'package:openimis_claim_policy_app/feature/shared/app_flavour/shared_main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final appConfig = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: EnvDev.apiBaseUrl,
    appApiKey: EnvDev.apiKey,
    dataMode: EnvDev.dataMode.toLowerCase() == 'demo'
        ? AppDataMode.demo
        : AppDataMode.live,
    googleMapsApiKey: EnvDev.googleMapsApiKey,
    launchTitle: 'openIMIS Dev',
    initializeCrashlytics: false,
  );
  sharedMain(appConfig);
}
