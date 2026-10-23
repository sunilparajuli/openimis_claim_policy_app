import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/my_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test - launches successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp(launchTitle: 'openIMIS Test')),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
