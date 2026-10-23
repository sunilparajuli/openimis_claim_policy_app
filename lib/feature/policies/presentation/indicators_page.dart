import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/remote/api/error/api_error.dart';
import '../repositories/report_repository.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/user_session_provider.dart';

class IndicatorsPage extends StatelessWidget {
  const IndicatorsPage({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: initialIndex,
    child: Scaffold(
      appBar: AppAppBar(
        title: Builder(
          builder: (context) {
            final tabs = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabs,
              builder: (context, _) => Text(
                tabs.index == 0
                    ? context.tr('Snapshot Indicators')
                    : context.tr('Cumulative Indicators'),
              ),
            );
          },
        ),
        bottom: TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: context.tr('Snapshot Indicators')),
            Tab(text: context.tr('Cumulative Indicators')),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _IndicatorReport(cumulative: false),
          _IndicatorReport(cumulative: true),
        ],
      ),
    ),
  );
}

class _IndicatorReport extends ConsumerStatefulWidget {
  const _IndicatorReport({required this.cumulative});
  final bool cumulative;
  @override
  ConsumerState<_IndicatorReport> createState() => _IndicatorReportState();
}

class _IndicatorReportState extends ConsumerState<_IndicatorReport> {
  final _form = GlobalKey<FormState>();
  final _officer = TextEditingController();
  DateTime _date = DateTime.now();
  DateTimeRange _range = DateTimeRange(
    start: DateTime(DateTime.now().year),
    end: DateTime.now(),
  );
  Map<String, num>? _data;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _officer.text =
        ref.read(userSessionProvider).value?.enrolmentOfficerCode ?? '';
  }

  @override
  void dispose() {
    _officer.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (widget.cumulative) {
      final range = await showAppDateRangePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        initialDateRange: _range,
      );
      if (range != null && mounted) {
        setState(() {
          _range = range;
          _data = null;
        });
      }
    } else {
      final date = await showAppDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (date != null && mounted) {
        setState(() {
          _date = date;
          _data = null;
        });
      }
    }
  }

  Future<void> _load() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });
    try {
      final result = await ref
          .read(reportRepositoryProvider)
          .indicators(
            _officer.text.trim(),
            widget.cumulative ? _range.start : _date,
            to: widget.cumulative ? _range.end : null,
          );
      if (mounted) setState(() => _data = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiError
              ? e.userMessage
              : 'Unable to load report. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.cumulative
        ? [
            ('NPC', context.tr('Number of New Policies'), 'new'),
            ('EPC', context.tr('Number of Expired Policies'), 'expired'),
            ('RPC', context.tr('Number of renewed Policies'), 'renewed'),
            ('SPC', context.tr('Number of Suspended Polices'), 'suspended'),
          ]
        : [
            (
              'FAPC',
              context.tr('Number of Families with Active Policies'),
              'active',
            ),
            (
              'FEPC',
              context.tr('Number of Families with Expired Policies'),
              'expired',
            ),
            (
              'FIPC',
              context.tr('Number of Families with Idle Policies'),
              'idle',
            ),
            (
              'FSPC',
              context.tr('Number of Families with Suspended Polices'),
              'suspended',
            ),
          ];
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            onChanged: (_) => setState(() => _data = null),
          ),
          const SizedBox(height: 12),
          if (!widget.cumulative)
            AppDateField(
              labelText: context.tr('Pick Date'),
              value: _date,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              enabled: !_loading,
              onChanged: (value) => setState(() {
                _date = value;
                _data = null;
              }),
            ),
          if (widget.cumulative)
            AppButton(
              variant: AppButtonVariant.secondary,
              onPressed: _loading ? null : _pick,
              icon: const Icon(Icons.date_range),
              label: Text(
                widget.cumulative
                    ? '${context.tr('Date From')}: ${ReportRepository.date(_range.start)}\n${context.tr('Date To')}: ${ReportRepository.date(_range.end)}'
                    : '${context.tr('Pick Date')}: ${ReportRepository.date(_date)}',
              ),
            ),
          AppButton(
            variant: AppButtonVariant.filled,
            onPressed: _load,
            isLoading: _loading,
            child: Text(_loading ? context.tr('Loading…') : context.tr('Get')),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) AppErrorMessage(message: context.tr(_error!)),
          if (_data == null && !_loading && _error == null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                context.tr(
                  'Choose an officer and reporting period, then get the report.',
                ),
              ),
            ),
          for (final metric in metrics)
            Card(
              child: ListTile(
                title: Text(metric.$2),
                trailing: Text(_data?[metric.$3]?.toString() ?? '—'),
              ),
            ),
          if (widget.cumulative)
            Card(
              child: ListTile(
                title: Text(context.tr('Amount of collected contribution')),
                subtitle: Text(
                  context.tr(
                    'Not available from the current reporting service.',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
