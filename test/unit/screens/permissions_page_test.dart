import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/core/native/app_permissions.dart';
import 'package:openimis_claim_policy_app/feature/settings/views/permissions_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppPermissions.channel, null);
  });

  testWidgets(
    'Permissions are requested only on tap and limited photos remain visible',
    (tester) async {
      final requested = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AppPermissions.channel, (call) async {
            if (call.method == 'status') return 'notRequested';
            if (call.method == 'request') {
              requested.add(call.arguments['permission'] as String);
              return 'limited';
            }
            return true;
          });
      await tester.pumpWidget(const MaterialApp(home: PermissionsPage()));
      await tester.pumpAndSettle();
      expect(requested, isEmpty);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Allow').at(1));
      await tester.pumpAndSettle();
      expect(requested, ['photos']);
      expect(find.textContaining('Selected photos only'), findsOneWidget);
    },
  );

  testWidgets('Denied access is reported without blocking the screen', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          AppPermissions.channel,
          (call) async => 'denied',
        );
    await tester.pumpWidget(const MaterialApp(home: PermissionsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Allow').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Access was not granted'), findsOneWidget);
    expect(find.text('Open Device Settings'), findsOneWidget);
  });
}
