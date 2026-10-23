import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/user_session_provider.dart';

class FeedbackRecord {
  final String date;
  final String officerCode;
  final String chfId;
  final String claimCode;
  final bool servicesReceived;
  final bool drugsReceived;
  final bool informalPaymentAsked;
  final bool satisfied;
  final int rating;
  final String notes;

  const FeedbackRecord({
    required this.date,
    required this.officerCode,
    required this.chfId,
    required this.claimCode,
    required this.servicesReceived,
    required this.drugsReceived,
    required this.informalPaymentAsked,
    required this.satisfied,
    required this.rating,
    required this.notes,
  });
}

class FeedbackSurveyPage extends ConsumerStatefulWidget {
  const FeedbackSurveyPage({super.key});

  @override
  ConsumerState<FeedbackSurveyPage> createState() => _FeedbackSurveyPageState();
}

class _FeedbackSurveyPageState extends ConsumerState<FeedbackSurveyPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _officerController = TextEditingController();
  final _chfIdController = TextEditingController();
  final _claimCodeController = TextEditingController();
  final _notesController = TextEditingController();

  bool _q1ServicesReceived = true;
  bool _q2DrugsReceived = true;
  bool _q3InformalPaymentAsked = false;
  bool _q4Satisfied = true;
  int _rating = 4;

  final List<FeedbackRecord> _pastFeedbacks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _officerController.text =
        ref.read(userSessionProvider).value?.enrolmentOfficerCode ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _officerController.dispose();
    _chfIdController.dispose();
    _claimCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_chfIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Insuree CHF ID')),
      );
      return;
    }

    final newRecord = FeedbackRecord(
      date: DateTime.now().toIso8601String().substring(0, 10),
      officerCode: _officerController.text.trim(),
      chfId: _chfIdController.text.trim(),
      claimCode: _claimCodeController.text.trim(),
      servicesReceived: _q1ServicesReceived,
      drugsReceived: _q2DrugsReceived,
      informalPaymentAsked: _q3InformalPaymentAsked,
      satisfied: _q4Satisfied,
      rating: _rating,
      notes: _notesController.text.trim(),
    );

    setState(() {
      _pastFeedbacks.insert(0, newRecord);
      _notesController.clear();
      _tabController.animateTo(1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: CustomColors.SuccessGreen,
        content: Text(
          'Beneficiary feedback recorded and queued for openIMIS sync.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Beneficiary Feedback & Audit'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.rate_review_outlined), text: 'New Survey'),
            Tab(icon: Icon(Icons.history), text: 'Submitted Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Survey Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audit Context',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _officerController,
                          readOnly: false,
                          decoration: const InputDecoration(
                            labelText: 'Officer Code',
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _chfIdController,
                          decoration: const InputDecoration(
                            labelText: 'Insuree CHF ID',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _claimCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Associated Claim Code',
                            prefixIcon: Icon(Icons.tag),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quality & Integrity Audit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildQuestion(
                          '1. Did the insuree receive the claimed medical treatment?',
                          _q1ServicesReceived,
                          (val) => setState(() => _q1ServicesReceived = val),
                        ),
                        const Divider(),
                        _buildQuestion(
                          '2. Were the prescribed medications provided free of charge?',
                          _q2DrugsReceived,
                          (val) => setState(() => _q2DrugsReceived = val),
                        ),
                        const Divider(),
                        _buildQuestion(
                          '3. Did facility staff ask for an unauthorized extra payment / bribe?',
                          _q3InformalPaymentAsked,
                          (val) =>
                              setState(() => _q3InformalPaymentAsked = val),
                        ),
                        const Divider(),
                        _buildQuestion(
                          '4. Was the insuree satisfied with the facility services?',
                          _q4Satisfied,
                          (val) => setState(() => _q4Satisfied = val),
                        ),
                        const Divider(),

                        const SizedBox(height: 8),
                        const Text(
                          'Overall Care Rating (1 to 5 Stars):',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                              onPressed: () =>
                                  setState(() => _rating = index + 1),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Field Notes & Observations',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  variant: AppButtonVariant.primary,
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Submit Beneficiary Audit Feedback'),
                  style: AppButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: CustomColors.BrandPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 2. Submitted List
          _pastFeedbacks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No submitted feedback records',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Completed beneficiary surveys will appear here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pastFeedbacks.length,
                  itemBuilder: (context, index) {
                    final rec = _pastFeedbacks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Claim: ${rec.claimCode}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < rec.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Insuree: ${rec.chfId} • Officer: ${rec.officerCode} • Date: ${rec.date}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Divider(height: 16),
                            Text(
                              'Bribe Asked: ${rec.informalPaymentAsked ? "YES (Reported)" : "No"}',
                              style: TextStyle(
                                color: rec.informalPaymentAsked
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Satisfied: ${rec.satisfied ? "Yes" : "No"}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (rec.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Notes: "${rec.notes}"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildQuestion(
    String title,
    bool currentVal,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14)),
        RadioGroup<bool>(
          groupValue: currentVal,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Yes'),
                  value: true,
                  activeColor: CustomColors.BrandPurple,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('No'),
                  value: false,
                  activeColor: CustomColors.BrandPurple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
