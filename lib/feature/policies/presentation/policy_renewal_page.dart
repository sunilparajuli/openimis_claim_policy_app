import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/config/currency_provider.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/graphql_service_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';

class PolicyRenewalPage extends ConsumerStatefulWidget {
  final String? initialChfId;

  const PolicyRenewalPage({super.key, this.initialChfId});

  @override
  ConsumerState<PolicyRenewalPage> createState() => _PolicyRenewalPageState();
}

class _PolicyRenewalPageState extends ConsumerState<PolicyRenewalPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _chfIdController;
  final _receiptNumberController = TextEditingController();
  final _payerNameController = TextEditingController();

  String _selectedProduct = 'UHC-Standard-Annual';
  String _payerType = 'Self';
  double _premiumAmount = 12000.0;
  bool _isRenewing = false;

  final Map<String, double> _productPremiums = {
    'UHC-Standard-Annual': 12000.0,
    'UHC-Comprehensive-Maternity': 18000.0,
    'UHC-Senior-Citizen': 8000.0,
  };

  MoneyFormatter get _money => ref.read(moneyFormatterProvider);

  @override
  void initState() {
    super.initState();
    _chfIdController = TextEditingController(text: widget.initialChfId ?? '');
  }

  @override
  void dispose() {
    _chfIdController.dispose();
    _receiptNumberController.dispose();
    _payerNameController.dispose();
    super.dispose();
  }

  Future<void> _renewPolicy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRenewing = true);

    const renewMutation = r'''
      mutation RenewPolicyMutation($input: PolicyRenewalInput!) {
        renewPolicy(input: $input) {
          success
          policy {
            code
            status
            validityTo
          }
        }
      }
    ''';

    try {
      final gql = ref.read(graphQLServiceProvider);
      final data = await gql.mutate(
        renewMutation,
        variables: {
          'input': {
            'chfId': _chfIdController.text.trim(),
            'productCode': _selectedProduct,
            'payerType': _payerType,
            'receiptNumber': _receiptNumberController.text.trim(),
            'premium': _premiumAmount,
          },
        },
      );
      final renewal = data['renewPolicy'];
      if (renewal is! Map || renewal['success'] != true) {
        throw const FormatException('The server did not confirm the renewal.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isRenewing = false);
      showAppFeedbackDialog(
        context: context,
        type: AppFeedbackType.error,
        message: 'Policy renewal failed: $error',
      );
      return;
    }

    setState(() => _isRenewing = false);

    if (!mounted) return;

    showAppBottomSheet(
      context: context,
      builder: (ctx) => AppSheetContent(
        icon: const Icon(
          Icons.check_circle,
          color: CustomColors.SuccessGreen,
          size: 48,
        ),
        title: Text(context.tr('Policy Renewed Successfully')),
        content: Text(
          'Policy for Insuree ${_chfIdController.text} has been renewed.\n\n'
          'Plan: $_selectedProduct\n'
          'Premium Paid: ${_money.format(_premiumAmount)}\n'
          'Receipt No: ${_receiptNumberController.text}',
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(context.tr('Done')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(moneyFormatterProvider);
    return Scaffold(
      appBar: AppAppBar(title: Text(context.tr('Policy Renewal Form'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        context.tr('Insuree & Policy Identification'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _chfIdController,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'Head of Family / Insuree CHF ID',
                          ),
                          prefixIcon: const Icon(Icons.badge),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'CHF ID is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppDropdownField<String>(
                        value: _selectedProduct,
                        decoration: InputDecoration(
                          labelText: context.tr('Health Insurance Plan'),
                          prefixIcon: const Icon(
                            Icons.health_and_safety_outlined,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        items: _productPremiums.keys.map((p) {
                          return DropdownMenuItem(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedProduct = val;
                              _premiumAmount = _productPremiums[val]!;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                        context.tr('Payment & Receipt Details'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppDropdownField<String>(
                        value: _payerType,
                        decoration: InputDecoration(
                          labelText: context.tr('Payer Type'),
                          prefixIcon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Self',
                            child: Text(
                              context.tr('Self (Individual / Household)'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Government',
                            child: Text(context.tr('Government Subsidy')),
                          ),
                          DropdownMenuItem(
                            value: 'Donor',
                            child: Text(context.tr('Donor / NGO Grant')),
                          ),
                        ],
                        onChanged: (val) => setState(() => _payerType = val!),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _payerNameController,
                        decoration: InputDecoration(
                          labelText: context.tr('Payer Name'),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _receiptNumberController,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'Bank / Mobile Money Receipt Number',
                          ),
                          prefixIcon: const Icon(Icons.receipt_long),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Receipt number is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CustomColors.BrandPurple.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CustomColors.BrandPurple.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('Calculated Premium:'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _money.format(_premiumAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: CustomColors.BrandPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                variant: AppButtonVariant.primary,
                onPressed: _isRenewing ? null : _renewPolicy,
                isLoading: _isRenewing,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(context.tr('Confirm & Submit Policy Renewal')),
                style: AppButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: CustomColors.BrandPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
