import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod_template/core/localization/app_localizations.dart';
import 'package:flutter_riverpod_template/core/native/app_permissions.dart';
import 'package:flutter_riverpod_template/feature/home/home_page.dart';
import 'package:flutter_riverpod_template/feature/settings/views/settings_page.dart';
import 'package:flutter_riverpod_template/feature/settings/views/permissions_page.dart';
import 'package:flutter_riverpod_template/feature/policies/presentation/indicators_page.dart';
import 'package:flutter_riverpod_template/feature/policies/presentation/reports_overview_page.dart';

Widget localized(Widget child, {Locale locale = const Locale('fr')}) =>
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('fr')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('Dashboard switches languages without changing card layout', (
    tester,
  ) async {
    await tester.pumpWidget(localized(const HomePage(title: 'Home')));
    await tester.pumpAndSettle();
    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(find.text('Accepté'), findsNothing);
    await tester.tap(find.text('Tableau de bord'));
    await tester.pumpAndSettle();
    expect(find.text('Accepté'), findsOneWidget);
    expect(find.text('Rejeté'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Accepté')).dy,
      tester.getTopLeft(find.text('Rejeté')).dy,
    );
    await tester.pumpWidget(
      localized(const HomePage(title: 'Home'), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Accepté'), findsNothing);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Accepted'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Currency settings include translated currency names and helper',
    (tester) async {
      await tester.pumpWidget(localized(const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Devise'), findsOneWidget);
      expect(find.text('USD — Dollar américain'), findsWidgets);
      expect(
        find.text(
          'Devise d’affichage uniquement ; les montants ne sont pas convertis.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Permissions translate titles and limited access status', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          AppPermissions.channel,
          (_) async => 'limited',
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AppPermissions.channel, null),
    );
    await tester.pumpWidget(localized(const PermissionsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Autorisations'), findsOneWidget);
    expect(find.text('Appareil photo'), findsOneWidget);
    expect(
      find.textContaining('Photos sélectionnées uniquement'),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reports translate titles, filters and validation', (
    tester,
  ) async {
    await tester.pumpWidget(localized(const IndicatorsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Indicateurs instantanés'), findsNWidgets(2));
    await tester.tap(find.text('Obtenir'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez un code d’agent'), findsOneWidget);
    await tester.pumpWidget(localized(const ReportsOverviewPage()));
    await tester.pumpAndSettle();
    expect(find.text('Vérifier la commission'), findsNWidgets(3));
    expect(find.text('Sélectionner un mois'), findsOneWidget);
    expect(find.text('Année'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
