import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/native/native_bridge.dart';
import 'package:openimis_claim_policy_app/data/app_providers/app_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/api_config.dart';
import 'package:openimis_claim_policy_app/feature/shared/app_flavour/app_config.dart';

import 'package:openimis_claim_policy_app/my_app.dart';

void sharedMain(AppConfig appConfig, {List overrides = const []}) async {
  await init(appConfig);

  final allOverrides = [
    appProvider.overrideWithValue(
      ApiConfig(
        appConfig.apiBaseUrl,
        apiKey: appConfig.appApiKey,
        demoMode: appConfig.dataMode == AppDataMode.demo,
      ),
    ),
    appConfigProvider.overrideWithValue(appConfig),
    ...overrides,
  ];
  runApp(
    ProviderScope(
      overrides: allOverrides.cast(),
      child: MyApp(launchTitle: appConfig.launchTitle),
    ),
  );
}

Future<void> init(AppConfig appConfig) async {
  if (appConfig.googleMapsApiKey.isNotEmpty) {
    await NativeBridge.initializeGoogleMaps(appConfig.googleMapsApiKey);
  }
}
