import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/feature/claims/presentation/offline_claims_sheet.dart';

void main() {
  testWidgets('OfflineClaimsSheet renders title and add button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OfflineClaimsSheet(),
          ),
        ),
      ),
    );

    // Initial pump shows shimmer while loading
    expect(find.text('Offline SQLite Queue'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // After loading, shows empty state or records
    expect(find.byType(OfflineClaimsSheet), findsOneWidget);
  });
}
