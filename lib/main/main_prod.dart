import 'package:flutter/widgets.dart';
import 'package:openimis_claim_policy_app/core/config/env.dart';
import 'package:openimis_claim_policy_app/feature/shared/app_flavour/app_config.dart';
import 'package:openimis_claim_policy_app/feature/shared/app_flavour/shared_main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final appConfig = AppConfig(
    environment: AppEnvironment.prod,
    apiBaseUrl: EnvProd.apiBaseUrl,
    appApiKey: EnvProd.apiKey,
    dataMode: EnvProd.dataMode.toLowerCase() == 'demo'
        ? AppDataMode.demo
        : AppDataMode.live,
    googleMapsApiKey: EnvProd.googleMapsApiKey,
    launchTitle: 'openIMIS',
    initializeCrashlytics: true,
  );
  sharedMain(appConfig);
}
