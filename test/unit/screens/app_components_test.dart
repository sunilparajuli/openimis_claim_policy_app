import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('Text input preserves validation, editing and submission', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final form = GlobalKey<FormState>();
    String? submitted;
    await tester.pumpWidget(
      host(
        Form(
          key: form,
          child: AppTextField(
            controller: controller,
            labelText: 'Code',
            validator: (value) => value!.isEmpty ? 'Required' : null,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'ABC');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(controller.text, 'ABC');
    expect(submitted, 'ABC');
    expect(form.currentState!.validate(), isTrue);
  });

  testWidgets('Every button variant supports loading and disabled actions', (
    tester,
  ) async {
    var taps = 0;
    for (final variant in AppButtonVariant.values) {
      await tester.pumpWidget(
        host(
          AppButton(
            variant: variant,
            onPressed: () => taps++,
            label: const Text('Save'),
            isLoading: true,
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      expect(taps, 0);
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(
      host(AppButton(onPressed: () => taps++, label: const Text('Save'))),
    );
    await tester.tap(find.text('Save'));
    expect(taps, 1);
  });

  testWidgets('Dropdown updates when the external selection changes', (
    tester,
  ) async {
    Widget dropdown(String? value) => host(
      AppDropdownField<String>(
        value: value,
        items: const [
          DropdownMenuItem(value: 'a', child: Text('A')),
          DropdownMenuItem(value: 'b', child: Text('B')),
        ],
        onChanged: (_) {},
      ),
    );
    await tester.pumpWidget(dropdown('a'));
    expect(
      tester
          .state<FormFieldState<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .value,
      'a',
    );
    await tester.pumpWidget(dropdown('b'));
    expect(
      tester
          .state<FormFieldState<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .value,
      'b',
    );
    await tester.pumpWidget(dropdown(null));
    expect(
      tester
          .state<FormFieldState<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .value,
      isNull,
    );
  });

  testWidgets('Autocomplete filters by code or name and returns selection', (
    tester,
  ) async {
    const options = ['SRV-001 General Consultation', 'LAB-004 Blood Count'];
    String? selected;
    await tester.pumpWidget(
      host(
        AppAutocompleteField<String>(
          options: options,
          displayStringForOption: (option) => option,
          onSelected: (option) => selected = option,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'lab-004');
    await tester.pump();
    expect(find.text('LAB-004 Blood Count'), findsOneWidget);
    expect(find.text('SRV-001 General Consultation'), findsNothing);

    await tester.tap(find.text('LAB-004 Blood Count'));
    await tester.pump();
    expect(selected, 'LAB-004 Blood Count');

    await tester.enterText(find.byType(TextFormField), 'consultation');
    await tester.pump();
    expect(find.text('SRV-001 General Consultation'), findsOneWidget);
  });

  testWidgets('Autocomplete results are constrained and scrollable', (
    tester,
  ) async {
    final options = List.generate(
      60,
      (index) => 'D${index.toString().padLeft(3, '0')} Diagnosis $index',
    );
    await tester.pumpWidget(
      host(
        AppAutocompleteField<String>(
          options: options,
          displayStringForOption: (option) => option,
          onSelected: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(find.byType(Scrollable), findsWidgets);
    expect(find.text('D000 Diagnosis 0'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('D000 Diagnosis 0'), findsNothing);
  });

  testWidgets('Date cancellation preserves value and external updates render', (
    tester,
  ) async {
    DateTime? selected;
    Widget field(DateTime date) => host(
      AppDateField(
        labelText: 'Date',
        value: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        onChanged: (value) => selected = value,
      ),
    );
    await tester.pumpWidget(field(DateTime(2026, 1, 1)));
    await tester.tap(find.byType(AppTextField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    await tester.pumpWidget(field(DateTime(2026, 2, 2)));
    expect(find.text('2/2/2026'), findsOneWidget);
  });

  testWidgets('App bar includes tab height', (tester) async {
    const bar = AppAppBar(
      title: Text('Claims'),
      bottom: TabBar(tabs: [Tab(text: 'All')]),
    );
    expect(bar.preferredSize.height, kToolbarHeight + kTextTabBarHeight);
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(length: 1, child: Scaffold(appBar: bar)),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
