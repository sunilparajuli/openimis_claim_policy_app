import 'package:flutter_riverpod_template/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod_template/core/config/currency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/feature/claims/presentation/claim_wizard_page.dart';
import 'package:flutter_riverpod_template/feature/insuree/models/insuree_model.dart';
import 'package:flutter_riverpod_template/feature/insuree/repositories/insuree_repository.dart';
import 'package:flutter_riverpod_template/feature/shared/utils/styles/app_color.dart';

class InsureeEnquiryPage extends ConsumerStatefulWidget {
  const InsureeEnquiryPage({super.key});

  @override
  ConsumerState<InsureeEnquiryPage> createState() => _InsureeEnquiryPageState();
}

class _InsureeEnquiryPageState extends ConsumerState<InsureeEnquiryPage> {
  final _chfIdController = TextEditingController();
  bool _isLoading = false;
  Insuree? _insuree;
  String? _errorMessage;

  MoneyFormatter get _money => ref.read(moneyFormatterProvider);

  @override
  void dispose() {
    _chfIdController.dispose();
    super.dispose();
  }

  Future<void> _searchInsuree() async {
    final query = _chfIdController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(insureeRepositoryProvider);
      final result = await repo.getInsureeByChfId(query);
      setState(() {
        _insuree = result;
        _errorMessage = result == null
            ? 'No insuree found with CHF ID: $query'
            : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to find insuree with CHF ID: $query';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(moneyFormatterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(title: const Text('Insuree Verification & Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar & Scan Action
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Insuree by CHF ID',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _chfIdController,
                            decoration: InputDecoration(
                              labelText: 'CHF ID / Card Number',
                              hintText: 'Enter CHF ID',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _searchInsuree(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          variant: AppButtonVariant.primary,
                          onPressed: _isLoading ? null : _searchInsuree,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: AppLoadingIndicator(inline: true),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Verify'),
                          style: AppButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const InsureeVerificationShimmer()
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_insuree != null) ...[
              // Insuree Profile Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          _insuree!.fullName.substring(0, 1),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _insuree!.fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CHF ID: ${_insuree!.chfId}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (_insuree!.dob != null)
                              Text(
                                'DOB: ${_insuree!.dob} • Gender: ${_insuree!.gender ?? 'N/A'}',
                              ),
                            if (_insuree!.healthFacilityName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.local_hospital,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _insuree!.healthFacilityName!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.grey.shade700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active Policy Details Card
              if (_insuree!.activePolicy != null) ...[
                Card(
                  elevation: 2,
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
                              'Policy Status',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _insuree!.activePolicy!.isActive
                                    ? CustomColors.SuccessGreen.withValues(
                                        alpha: 0.15,
                                      )
                                    : CustomColors.NavRed.withValues(
                                        alpha: 0.15,
                                      ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _insuree!.activePolicy!.status,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _insuree!.activePolicy!.isActive
                                      ? CustomColors.SuccessGreen
                                      : CustomColors.NavRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          _insuree!.activePolicy!.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Code: ${_insuree!.activePolicy!.code}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_insuree!.activePolicy!.expiryDate != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'Valid Until: ${_insuree!.activePolicy!.expiryDate}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'Benefit Balances & Limits',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                'OP Ceiling',
                                _money.format(
                                  _insuree!.activePolicy!.ceilingOp,
                                ),
                                Icons.medical_services_outlined,
                                CustomColors.BrandPurple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricTile(
                                'IP Ceiling',
                                _money.format(
                                  _insuree!.activePolicy!.ceilingIp,
                                ),
                                Icons.hotel_outlined,
                                CustomColors.BlueIcon,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                'Visits Left',
                                '${_insuree!.activePolicy!.totalVisitsLeft ?? 'Unlimited'}',
                                Icons.confirmation_number_outlined,
                                CustomColors.ExpiryOrange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricTile(
                                'Consultations',
                                '${_insuree!.activePolicy!.totalConsultationsLeft ?? 'Unlimited'}',
                                Icons.person_search_outlined,
                                CustomColors.BrandGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action: Start Claim for this Insuree
                AppButton(
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ClaimWizardPage(prefilledInsuree: _insuree),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('Start New Claim for this Insuree'),
                  style: AppButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
