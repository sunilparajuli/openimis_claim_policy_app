import 'package:flutter_riverpod_template/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod_template/core/config/currency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/data/remote/graphql/graphql_service_provider.dart';
import 'package:flutter_riverpod_template/feature/shared/utils/styles/app_color.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Policy renewal failed: $error'),
        ),
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
        title: const Text('Policy Renewed Successfully'),
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
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(moneyFormatterProvider);
    return Scaffold(
      appBar: AppAppBar(title: const Text('Policy Renewal Form')),
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
                      const Text(
                        'Insuree & Policy Identification',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _chfIdController,
                        decoration: const InputDecoration(
                          labelText: 'Head of Family / Insuree CHF ID',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'CHF ID is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppDropdownField<String>(
                        value: _selectedProduct,
                        decoration: const InputDecoration(
                          labelText: 'Health Insurance Plan',
                          prefixIcon: Icon(Icons.health_and_safety_outlined),
                          border: OutlineInputBorder(),
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
                      const Text(
                        'Payment & Receipt Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppDropdownField<String>(
                        value: _payerType,
                        decoration: const InputDecoration(
                          labelText: 'Payer Type',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Self',
                            child: Text('Self (Individual / Household)'),
                          ),
                          DropdownMenuItem(
                            value: 'Government',
                            child: Text('Government Subsidy'),
                          ),
                          DropdownMenuItem(
                            value: 'Donor',
                            child: Text('Donor / NGO Grant'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _payerType = val!),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _payerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Payer Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _receiptNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Bank / Mobile Money Receipt Number',
                          prefixIcon: Icon(Icons.receipt_long),
                          border: OutlineInputBorder(),
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
                            const Text(
                              'Calculated Premium:',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                label: const Text('Confirm & Submit Policy Renewal'),
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
