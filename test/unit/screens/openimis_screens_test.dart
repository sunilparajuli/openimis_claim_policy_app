import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/app_providers/app_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/api_config.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claims_listing_page.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/service_item_catalog_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/family_enrolment_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/feedback_survey_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/indicators_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/reports_overview_page.dart';
import 'package:openimis_claim_policy_app/feature/shared/presentation/about_openimis_page.dart';

void main() {
  group('openIMIS Screen Architecture Tests (Java Replication)', () {
    testWidgets('Claims tabs fit phone widths and enlarged text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final width in [402.0, 375.0, 320.0]) {
        tester.view.physicalSize = Size(width, 874);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appProvider.overrideWithValue(
                ApiConfig('', apiKey: '', demoMode: true),
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.3)),
                child: child!,
              ),
              home: const ClaimsListingPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final tabs = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabs.isScrollable, isTrue);
        expect(tabs.labelColor, Colors.white);
        expect(tabs.unselectedLabelColor, Colors.white);
        final rejectedTab = find.descendant(
          of: find.byType(TabBar),
          matching: find.text('REJECTED'),
        );
        await tester.ensureVisible(rejectedTab);
        await tester.pumpAndSettle();
        await tester.tap(rejectedTab);
        await tester.pumpAndSettle();
        expect(find.text('CLM-78350'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('ClaimsListingPage renders tabs and allows switching', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appProvider.overrideWithValue(
              ApiConfig('', apiKey: '', demoMode: true),
            ),
          ],
          child: const MaterialApp(home: ClaimsListingPage()),
        ),
      );

      expect(find.text('Claims Listing'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Check 3 status tabs matching ClaimListingActivity.java
      Finder statusTab(String label) =>
          find.descendant(of: find.byType(TabBar), matching: find.text(label));
      expect(statusTab('ENTERED / PENDING'), findsOneWidget);
      expect(statusTab('ACCEPTED'), findsOneWidget);
      expect(statusTab('REJECTED'), findsOneWidget);

      expect(find.text('CLM-78401'), findsOneWidget);

      // Switch to Accepted tab
      await tester.tap(statusTab('ACCEPTED'));
      await tester.pumpAndSettle();
      expect(find.text('CLM-78390'), findsOneWidget);

      // Switch to Rejected tab
      final rejectedTab = statusTab('REJECTED');
      await tester.ensureVisible(rejectedTab);
      await tester.tap(rejectedTab);
      await tester.pumpAndSettle();
      expect(find.text('CLM-78350'), findsOneWidget);
    });

    testWidgets('ServiceItemCatalogPage renders services and items tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ServiceItemCatalogPage())),
      );

      expect(find.text('Facility Services & Items Mapping'), findsOneWidget);
      expect(find.text('Services (0)'), findsOneWidget);
      expect(find.text('Items (0)'), findsOneWidget);

      // Switch to Items tab
      await tester.tap(find.text('Items (0)'));
      await tester.pumpAndSettle();
      expect(find.text('Items (0)'), findsOneWidget);
    });

    testWidgets('FamilyEnrolmentPage renders household registration details', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FamilyEnrolmentPage())),
      );

      expect(find.text('Family & Insuree Enrolment'), findsOneWidget);
      expect(find.text('Enrol Family'), findsOneWidget);
      expect(find.text('No enrolled families available'), findsOneWidget);

      // Tap to open household enrolment modal
      await tester.tap(find.text('Enrol Family'));
      await tester.pumpAndSettle();

      expect(find.text('New Household Enrolment'), findsOneWidget);
      expect(find.text('Head of Household Name'), findsOneWidget);
    });

    testWidgets(
      'FeedbackSurveyPage renders audit survey questions and submission tab',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: FeedbackSurveyPage())),
        );

        expect(find.text('Beneficiary Feedback & Audit'), findsOneWidget);
        expect(find.text('New Survey'), findsOneWidget);
        expect(find.text('Submitted Records'), findsOneWidget);

        // Switch to Submitted Records tab
        await tester.tap(find.text('Submitted Records'));
        await tester.pumpAndSettle();

        expect(find.text('No submitted feedback records'), findsOneWidget);
      },
    );

    testWidgets(
      'IndicatorsPage renders KPI metrics from SnapshotIndicators and CumulativeIndicators',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: IndicatorsPage())),
        );

        expect(find.text('Snapshot Indicators'), findsNWidgets(2));
        expect(find.text('Cumulative Indicators'), findsOneWidget);

        // Verify specific Java metrics
        expect(
          find.text('Number of Families with Active Policies'),
          findsOneWidget,
        );
        expect(
          find.text('Number of Families with Expired Policies'),
          findsOneWidget,
        );

        // Switch to Cumulative tab
        await tester.tap(find.text('Cumulative Indicators'));
        await tester.pumpAndSettle();

        expect(find.text('Number of New Policies'), findsOneWidget);
        expect(find.text('Number of renewed Policies'), findsOneWidget);
      },
    );

    testWidgets(
      'ReportsOverviewPage renders Enrolment Officer Commission and Claims breakdown',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: ReportsOverviewPage())),
        );

        expect(find.text('Check Commission'), findsNWidgets(3));
        expect(find.text('Reports'), findsOneWidget);

        // Check commission calculations
        expect(find.text('Enrolment officer code'), findsOneWidget);

        // Switch to Claims & Enrolment Report tab
        await tester.tap(find.widgetWithText(Tab, 'Reports'));
        await tester.pumpAndSettle();

        expect(find.text('Snapshot Indicators'), findsOneWidget);
        expect(find.text('Cumulative Indicators'), findsOneWidget);
        await tester.tap(find.text('Cumulative Indicators'));
        await tester.pumpAndSettle();
        expect(find.text('Number of New Policies'), findsOneWidget);
      },
    );

    testWidgets(
      'AboutOpenImisPage renders openIMIS initiative metadata and licenses',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: AboutOpenImisPage())),
        );

        expect(find.text('About openIMIS'), findsOneWidget);
        expect(find.text('openIMIS Mobile Suite'), findsOneWidget);
        expect(find.text('2.1.0 (Build 2026.10)'), findsOneWidget);
        expect(
          find.textContaining('Swiss Agency for Development and Cooperation'),
          findsOneWidget,
        );
      },
    );
  });
}
