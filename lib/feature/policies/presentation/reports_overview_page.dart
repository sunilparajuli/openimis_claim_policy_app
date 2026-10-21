import 'package:flutter_riverpod_template/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod_template/core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/data/remote/api/error/api_error.dart';
import '../repositories/report_repository.dart';
import 'indicators_page.dart';
import 'package:flutter_riverpod_template/core/config/currency_provider.dart';
import 'package:flutter_riverpod_template/feature/shared/providers/user_session_provider.dart';

class ReportsOverviewPage extends StatelessWidget {
  const ReportsOverviewPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppAppBar(
        title: Builder(
          builder: (context) {
            final tabs = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabs,
              builder: (context, _) => Text(
                tabs.index == 0
                    ? context.tr('Check Commission')
                    : context.tr('Reports'),
              ),
            );
          },
        ),
        bottom: TabBar(
          tabs: [
            Tab(text: context.tr('Check Commission')),
            Tab(text: context.tr('Reports')),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          const _CommissionForm(),
          ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.tr('Snapshot Indicators')),
                subtitle: Text(context.tr('Policy status at a selected date')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const IndicatorsPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timeline),
                title: Text(context.tr('Cumulative Indicators')),
                subtitle: Text(
                  context.tr('New, renewed, expired and suspended policies'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const IndicatorsPage(initialIndex: 1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CommissionForm extends ConsumerStatefulWidget {
  const _CommissionForm();
  @override
  ConsumerState<_CommissionForm> createState() => _CommissionFormState();
}

class _CommissionFormState extends ConsumerState<_CommissionForm> {
  final _form = GlobalKey<FormState>();
  final _officer = TextEditingController();
  final _product = TextEditingController();
  final _payer = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  int _month = DateTime.now().month;
  bool _paid = true;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>>? _rows;
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _officer.text =
        ref.read(userSessionProvider).value?.enrolmentOfficerCode ?? '';
  }

  @override
  void dispose() {
    for (final c in [_officer, _product, _payer, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _check() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _rows = null;
    });
    try {
      final rows = await ref
          .read(reportRepositoryProvider)
          .commission(
            officer: _officer.text.trim(),
            month: _month,
            year: int.parse(_year.text),
            product: _product.text.trim(),
            payer: _payer.text.trim(),
            paid: _paid,
          );
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiError
              ? e.userMessage
              : e is FormatException
              ? e.message
              : 'Unable to check commission. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    onChanged: () {
      if (_rows != null) setState(() => _rows = null);
    },
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.tr('Check Commission'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _officer,
          enabled: !_loading,
          readOnly: false,
          decoration: InputDecoration(
            labelText: context.tr('Enrolment officer code'),
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? context.tr('Enter an officer code')
              : null,
        ),
        const SizedBox(height: 12),
        AppDropdownField<int>(
          value: _month,
          decoration: InputDecoration(labelText: context.tr('Select Month')),
          items: List.generate(
            12,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(context.tr(_months[i])),
            ),
          ),
          onChanged: _loading
              ? null
              : (v) => setState(() {
                  _month = v!;
                  _rows = null;
                }),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _year,
          enabled: !_loading,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.tr('Year')),
          validator: (v) {
            final year = int.tryParse(v ?? '');
            return year == null || year < 1000 || year > 9999
                ? context.tr('Enter a four-digit year')
                : null;
          },
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _product,
          enabled: !_loading,
          decoration: InputDecoration(
            labelText: context.tr('Select Product'),
            helperText: context.tr('Optional — leave blank for all products'),
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _payer,
          enabled: !_loading,
          decoration: InputDecoration(
            labelText: context.tr('Select Payer'),
            helperText: context.tr('Optional — leave blank for all payers'),
          ),
        ),
        const SizedBox(height: 12),
        AppDropdownField<bool>(
          value: _paid,
          decoration: InputDecoration(labelText: context.tr('Mode')),
          items: [
            DropdownMenuItem(value: true, child: Text(context.tr('Paid'))),
            DropdownMenuItem(
              value: false,
              child: Text(context.tr('Prescribed')),
            ),
          ],
          onChanged: _loading
              ? null
              : (v) => setState(() {
                  _paid = v!;
                  _rows = null;
                }),
        ),
        const SizedBox(height: 16),
        AppButton(
          variant: AppButtonVariant.filled,
          onPressed: _loading ? null : _check,
          child: Text(
            _loading ? context.tr('Get Commissions') : context.tr('Check'),
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) AppErrorMessage(message: context.tr(_error!)),
        if (_rows != null && _rows!.isEmpty)
          AppEmptyState(message: context.tr('No data')),
        if (_rows != null && _rows!.isNotEmpty)
          Text(context.tr('Commissions Report')),
        if (_rows != null)
          for (final row in _rows!)
            Card(
              child: ListTile(
                title: Text(
                  'commissions: ${ref.watch(moneyFormatterProvider).format(row['commission'])}',
                ),
                subtitle: Text(
                  '${context.tr('Amount')}: ${ref.watch(moneyFormatterProvider).format(row['amount'])}',
                ),
              ),
            ),
      ],
    ),
  );
}
