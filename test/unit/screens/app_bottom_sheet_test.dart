import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod_template/feature/shared/widgets/app_bottom_sheet.dart';

void main() {
  testWidgets('Tablet sheets are wide and actions return their result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showAppBottomSheet<String>(
                  context: context,
                  builder: (context) => AppSheetContent(
                    title: const Text('Confirmation'),
                    content: const Text('Details'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'saved'),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.getSize(find.byType(AppSheetContent)).width, 1152);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, 'saved');
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('Long forms remain scrollable above the phone keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                builder: (context) => AppSheetContent(
                  title: const Text('Form'),
                  content: Column(
                    children: List.generate(
                      12,
                      (i) => TextField(
                        decoration: InputDecoration(labelText: 'Field $i'),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.text('Save')).dy, lessThan(544));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AppSheetContent), findsNothing);
  });
}
