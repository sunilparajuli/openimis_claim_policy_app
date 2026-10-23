import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/offline_claims_sheet.dart';

void main() {
  testWidgets('OfflineClaimsSheet renders title and add button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: OfflineClaimsSheet())),
      ),
    );

    expect(find.text('Pending Claims'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(OfflineClaimsSheet), findsOneWidget);
  });
}
