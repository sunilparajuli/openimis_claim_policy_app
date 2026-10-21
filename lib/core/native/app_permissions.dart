import 'package:flutter/services.dart';

/// Shared permission interface; native requests preserve the OS consent flow.
class AppPermissions {
  static const channel = MethodChannel('org.openimis/permissions');

  static Future<String> status(String permission) async =>
      await channel.invokeMethod<String>('status', {
        'permission': permission,
      }) ??
      'unavailable';

  static Future<String> request(String permission) async =>
      await channel.invokeMethod<String>('request', {
        'permission': permission,
      }) ??
      'unavailable';

  static Future<void> openSettings() async {
    await channel.invokeMethod<bool>('openSettings');
  }
}
