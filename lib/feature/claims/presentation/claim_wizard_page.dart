import 'package:flutter_riverpod_template/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod_template/core/config/currency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_service_item_model.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_submission_model.dart';
import 'package:flutter_riverpod_template/feature/claims/models/diagnosis_model.dart';
import 'package:flutter_riverpod_template/feature/claims/repositories/claim_repository.dart';
import 'package:flutter_riverpod_template/feature/claims/repositories/offline_claim_repository.dart';
import 'package:flutter_riverpod_template/feature/insuree/models/insuree_model.dart';
import 'package:flutter_riverpod_template/feature/shared/utils/styles/app_color.dart';
import 'package:flutter_riverpod_template/feature/shared/providers/user_session_provider.dart';
import 'package:flutter_riverpod_template/data/remote/api/error/api_error.dart';

class ClaimWizardPage extends ConsumerStatefulWidget {
  final Insuree? prefilledInsuree;

  const ClaimWizardPage({super.key, this.prefilledInsuree});

  @override
  ConsumerState<ClaimWizardPage> createState() => _ClaimWizardPageState();
}

class _ClaimWizardPageState extends ConsumerState<ClaimWizardPage> {
  int _currentStep = 0;

  // Form Fields - Step 1: Patient & Context
  late final TextEditingController _chfIdController;
  late final TextEditingController _claimCodeController;
  late final TextEditingController _healthFacilityController;
  late final TextEditingController _claimAdminController;
  final _guaranteeNoController = TextEditingController();
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  final DateTime _endDate = DateTime.now();
  ClaimVisitType _visitType = ClaimVisitType.emergency;

  // Step 2: Diagnoses
  Diagnosis? _primaryDiagnosis;
  final List<Diagnosis> _secondaryDiagnoses = [];

  // Step 3 & 4: Services and Items
  final List<ClaimedService> _selectedServices = [];
  final List<ClaimedItem> _selectedItems = [];

  bool _isSubmitting = false;

  MoneyFormatter get _money => ref.read(moneyFormatterProvider);

  @override
  void initState() {
    super.initState();
    _chfIdController = TextEditingController(
      text: widget.prefilledInsuree?.chfId ?? '',
    );
    final session = ref.read(userSessionProvider).value;
    _healthFacilityController = TextEditingController(
      text: session?.healthFacilityName ?? '',
    );
    _claimAdminController = TextEditingController(
      text: session?.claimAdminCode ?? '',
    );
    final randomSuffix = DateTime.now().millisecondsSinceEpoch % 1000000;
    _claimCodeController = TextEditingController(text: 'CLM-$randomSuffix');
  }

  @override
  void dispose() {
    _chfIdController.dispose();
    _claimCodeController.dispose();
    _healthFacilityController.dispose();
    _claimAdminController.dispose();
    _guaranteeNoController.dispose();
    super.dispose();
  }

  double get _servicesTotal =>
      _selectedServices.fold(0.0, (sum, s) => sum + s.total);

  double get _itemsTotal => _selectedItems.fold(0.0, (sum, i) => sum + i.total);

  double get _grandTotal => _servicesTotal + _itemsTotal;

  Future<void> _submitClaim() async {
    if (_primaryDiagnosis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Primary Diagnosis')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final submission = ClaimSubmission(
      claimCode: _claimCodeController.text.trim(),
      healthFacility: _healthFacilityController.text.trim(),
      claimAdmin: _claimAdminController.text.trim(),
      insureeChfId: _chfIdController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      claimDate: DateTime.now(),
      visitType: _visitType,
      guaranteeNo: _guaranteeNoController.text.trim().isEmpty
          ? null
          : _guaranteeNoController.text.trim(),
      primaryDiagnosis: _primaryDiagnosis!,
      secondaryDiagnoses: _secondaryDiagnoses,
      services: _selectedServices,
      items: _selectedItems,
    );

    try {
      final success = await ref
          .read(claimRepositoryProvider)
          .submitClaim(submission);
      if (!mounted) return;
      if (!success) {
        throw const FormatException('The server did not accept this claim.');
      }

      showAppBottomSheet(
        context: context,
        builder: (ctx) => AppSheetContent(
          icon: const Icon(
            Icons.check_circle,
            color: CustomColors.SuccessGreen,
            size: 48,
          ),
          title: const Text('Claim Submitted Successfully'),
          content: Text(
            'Claim ${submission.claimCode} has been sent to openIMIS FHIR server.\n\nTotal Claimed: ${_money.format(_grandTotal)}',
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
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiError
          ? error.userMessage
          : error.toString().replaceFirst('FormatException: ', '');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Save Offline',
              onPressed: _saveOfflineClaim,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveOfflineClaim() async {
    if (_primaryDiagnosis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Primary Diagnosis')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final submission = ClaimSubmission(
      claimCode: _claimCodeController.text.trim(),
      healthFacility: _healthFacilityController.text.trim(),
      claimAdmin: _claimAdminController.text.trim(),
      insureeChfId: _chfIdController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      claimDate: DateTime.now(),
      visitType: _visitType,
      guaranteeNo: _guaranteeNoController.text.trim().isEmpty
          ? null
          : _guaranteeNoController.text.trim(),
      primaryDiagnosis: _primaryDiagnosis!,
      secondaryDiagnoses: _secondaryDiagnoses,
      services: _selectedServices,
      items: _selectedItems,
    );

    await ref.read(pendingClaimsCountProvider.notifier).saveOffline(submission);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    showAppBottomSheet(
      context: context,
      builder: (ctx) => AppSheetContent(
        icon: const Icon(
          Icons.storage_rounded,
          color: CustomColors.BrandPurple,
          size: 48,
        ),
        title: const Text('Claim Saved Offline (SQLite)'),
        content: Text(
          'Claim ${submission.claimCode} has been stored in local openIMIS SQLite database:\n\n• tblClaimDetails\n• tblClaimItems\n• tblClaimServices\n• tblClaimUploadStatus (pending)\n\nYou can synchronize it anytime from the Home screen offline queue.',
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
      appBar: AppAppBar(
        title: const Text('New Claim Form'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            color: CustomColors.BrandPurple.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Insuree: ${_chfIdController.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Running Total: ${_money.format(_grandTotal)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep += 1);
          } else {
            _submitClaim();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 4;
          if (isLastStep) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      variant: AppButtonVariant.primary,
                      onPressed: _isSubmitting ? null : _submitClaim,
                      isLoading: _isSubmitting,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Submit FHIR Claim (Online)'),
                      style: AppButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: CustomColors.BrandPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          variant: AppButtonVariant.secondary,
                          onPressed: _isSubmitting ? null : _saveOfflineClaim,
                          icon: const Icon(
                            Icons.storage_rounded,
                            color: CustomColors.BrandPurple,
                          ),
                          label: const Text(
                            'Save Offline (SQLite)',
                            style: TextStyle(color: CustomColors.BrandPurple),
                          ),
                          style: AppButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: CustomColors.BrandPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        variant: AppButtonVariant.secondary,
                        onPressed: _isSubmitting ? null : details.onStepCancel,
                        style: AppButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    variant: AppButtonVariant.primary,
                    onPressed: _isSubmitting ? null : details.onStepContinue,
                    style: AppButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  AppButton(
                    variant: AppButtonVariant.secondary,
                    onPressed: _isSubmitting ? null : details.onStepCancel,
                    style: AppButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Visit & Facility Details'),
            isActive: _currentStep >= 0,
            content: _buildStep1FacilityInfo(),
          ),
          Step(
            title: const Text('Diagnoses (ICD-10)'),
            isActive: _currentStep >= 1,
            content: _buildStep2Diagnoses(),
          ),
          Step(
            title: Text('Medical Services (${_selectedServices.length})'),
            isActive: _currentStep >= 2,
            content: _buildStep3Services(),
          ),
          Step(
            title: Text('Medications & Items (${_selectedItems.length})'),
            isActive: _currentStep >= 3,
            content: _buildStep4Items(),
          ),
          Step(
            title: const Text('Review & Adjudication'),
            isActive: _currentStep >= 4,
            content: _buildStep5Review(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1FacilityInfo() {
    return Column(
      children: [
        AppTextField(
          controller: _chfIdController,
          decoration: const InputDecoration(
            labelText: 'Insuree CHF ID',
            prefixIcon: Icon(Icons.badge),
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _claimCodeController,
          decoration: const InputDecoration(
            labelText: 'Claim Code / Number',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _healthFacilityController,
          decoration: const InputDecoration(
            labelText: 'Health Facility',
            prefixIcon: Icon(Icons.local_hospital),
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _claimAdminController,
          decoration: const InputDecoration(
            labelText: 'Claim Administrator / Doctor',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),
        AppDropdownField<ClaimVisitType>(
          value: _visitType,
          decoration: const InputDecoration(
            labelText: 'Visit Type',
            prefixIcon: Icon(Icons.emergency),
          ),
          items: ClaimVisitType.values.map((vt) {
            return DropdownMenuItem(value: vt, child: Text(vt.label));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _visitType = val);
          },
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _guaranteeNoController,
          decoration: const InputDecoration(
            labelText: 'Guarantee Number (Optional)',
            prefixIcon: Icon(Icons.security),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Diagnoses() {
    final repo = ref.read(claimRepositoryProvider);
    final allDiagnoses = repo.getDiagnoses();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Diagnosis (Mandatory)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        AppAutocompleteField<Diagnosis>(
          key: ValueKey(_primaryDiagnosis?.code),
          options: allDiagnoses,
          initialValue: _primaryDiagnosis,
          labelText: 'Primary ICD-10 Diagnosis',
          hintText: 'Type an ICD code or diagnosis name',
          prefixIcon: const Icon(Icons.search),
          displayStringForOption: (diagnosis) =>
              '${diagnosis.code}: ${diagnosis.name}',
          searchStringForOption: (diagnosis) =>
              '${diagnosis.code} ${diagnosis.name}',
          onSelected: (diagnosis) => setState(() {
            _primaryDiagnosis = diagnosis;
            _secondaryDiagnoses.removeWhere(
              (secondary) => secondary.code == diagnosis.code,
            );
          }),
          onCleared: () => setState(() => _primaryDiagnosis = null),
        ),
        const SizedBox(height: 20),
        const Text(
          'Secondary Diagnoses (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._secondaryDiagnoses.map(
          (d) => ListTile(
            leading: const Icon(
              Icons.check_circle_outline,
              color: CustomColors.BrandPurple,
            ),
            title: Text('${d.code}: ${d.name}'),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: CustomColors.NavRed,
              ),
              onPressed: () => setState(() => _secondaryDiagnoses.remove(d)),
            ),
          ),
        ),
        AppButton(
          variant: AppButtonVariant.secondary,
          onPressed: () => _showAddDiagnosisDialog(allDiagnoses),
          icon: const Icon(Icons.add),
          label: const Text('Add Secondary Diagnosis'),
        ),
      ],
    );
  }

  Widget _buildStep3Services() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppMoneySummaryRow(
          label: 'Claimed Medical Services',
          value: 'Subtotal: ${_money.format(_servicesTotal)}',
          emphasized: true,
        ),
        const SizedBox(height: 8),
        if (_selectedServices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'No services added yet. Tap below to add a service.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._selectedServices.map(
            (cs) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(cs.service.name),
                subtitle: Text(
                  'Qty: ${cs.quantity} × ${_money.format(cs.price)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _money.format(cs.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: CustomColors.NavRed,
                      ),
                      onPressed: () =>
                          setState(() => _selectedServices.remove(cs)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        AppButton(
          variant: AppButtonVariant.primary,
          onPressed: _showAddServiceDialog,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Medical Service'),
        ),
      ],
    );
  }

  Widget _buildStep4Items() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppMoneySummaryRow(
          label: 'Medications & Consumables',
          value: 'Subtotal: ${_money.format(_itemsTotal)}',
          emphasized: true,
        ),
        const SizedBox(height: 8),
        if (_selectedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'No medications/items added yet.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._selectedItems.map(
            (ci) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(ci.item.name),
                subtitle: Text(
                  'Qty: ${ci.quantity} × ${_money.format(ci.price)} (${ci.item.unit ?? "unit"})',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _money.format(ci.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: CustomColors.NavRed,
                      ),
                      onPressed: () =>
                          setState(() => _selectedItems.remove(ci)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        AppButton(
          variant: AppButtonVariant.primary,
          onPressed: _showAddItemDialog,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Medication / Item'),
        ),
      ],
    );
  }

  Widget _buildStep5Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: CustomColors.SuccessGreen.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Total Claim Amount',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _money.format(_grandTotal),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CustomColors.SuccessGreen,
                    ),
                  ),
                ),
                const Divider(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    Text('Services: ${_money.format(_servicesTotal)}'),
                    Text('Medications: ${_money.format(_itemsTotal)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          dense: true,
          title: const Text('Insuree CHF ID'),
          subtitle: Text(_chfIdController.text),
        ),
        ListTile(
          dense: true,
          title: const Text('Health Facility'),
          subtitle: Text(_healthFacilityController.text),
        ),
        ListTile(
          dense: true,
          title: const Text('Primary Diagnosis'),
          subtitle: Text(
            _primaryDiagnosis != null
                ? '${_primaryDiagnosis!.code} - ${_primaryDiagnosis!.name}'
                : 'None',
          ),
        ),
        ListTile(
          dense: true,
          title: const Text('Visit Type'),
          subtitle: Text(_visitType.label),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CustomColors.BrandPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CustomColors.BrandPurple.withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.offline_bolt_outlined,
                color: CustomColors.BrandPurple,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Offline Storage Ready: If network is unavailable, save locally to SQLite (tblClaimDetails) and sync later.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddDiagnosisDialog(List<Diagnosis> allDiagnoses) {
    final pendingDiagnoses = List<Diagnosis>.of(_secondaryDiagnoses);
    showAppBottomSheet(
      context: context,
      heightFactor: 0.62,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableDiagnoses = allDiagnoses.where(
            (diagnosis) =>
                _primaryDiagnosis?.code != diagnosis.code &&
                !pendingDiagnoses.any((item) => item.code == diagnosis.code),
          );
          return AppSheetContent(
            title: const Text('Add Secondary Diagnoses'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Search by ICD-10 code or diagnosis name. Select as many as needed, then press Done.',
                ),
                const SizedBox(height: 12),
                AppAutocompleteField<Diagnosis>(
                  key: ValueKey(pendingDiagnoses.length),
                  options: availableDiagnoses,
                  labelText: 'Secondary ICD-10 Diagnosis',
                  hintText: 'Type an ICD code or diagnosis name',
                  prefixIcon: const Icon(Icons.search),
                  displayStringForOption: (diagnosis) =>
                      '${diagnosis.code}: ${diagnosis.name}',
                  searchStringForOption: (diagnosis) =>
                      '${diagnosis.code} ${diagnosis.name}',
                  onSelected: (diagnosis) =>
                      setModalState(() => pendingDiagnoses.add(diagnosis)),
                ),
                if (pendingDiagnoses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Selected (${pendingDiagnoses.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pendingDiagnoses
                        .map(
                          (diagnosis) => InputChip(
                            label: Text('${diagnosis.code}: ${diagnosis.name}'),
                            onDeleted: () => setModalState(
                              () => pendingDiagnoses.remove(diagnosis),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
            actions: [
              AppButton(
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.pop(ctx),
                label: const Text('Cancel'),
              ),
              AppButton(
                onPressed: () {
                  setState(() {
                    _secondaryDiagnoses
                      ..clear()
                      ..addAll(pendingDiagnoses);
                  });
                  Navigator.pop(ctx);
                },
                label: Text('Done (${pendingDiagnoses.length})'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddServiceDialog() {
    final services = ref.read(claimRepositoryProvider).getAvailableServices();
    MedicalService? selectedService;
    int quantity = 1;

    showAppBottomSheet(
      context: context,
      heightFactor: 0.62,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AppSheetContent(
          title: const Text('Add Medical Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAutocompleteField<MedicalService>(
                options: services,
                labelText: 'Medical Service',
                hintText: 'Type a service name or code',
                prefixIcon: const Icon(Icons.medical_services_outlined),
                displayStringForOption: (service) =>
                    '${service.code} — ${service.name} (${_money.format(service.price)})',
                searchStringForOption: (service) =>
                    '${service.code} ${service.name} ${service.category ?? ''}',
                onSelected: (service) =>
                    setModalState(() => selectedService = service),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () => setModalState(() => quantity--)
                            : null,
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setModalState(() => quantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              variant: AppButtonVariant.primary,
              onPressed: selectedService == null
                  ? null
                  : () {
                      setState(() {
                        _selectedServices.add(
                          ClaimedService(
                            service: selectedService!,
                            quantity: quantity,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final items = ref.read(claimRepositoryProvider).getAvailableItems();
    MedicationItem? selectedItem;
    int quantity = 1;

    showAppBottomSheet(
      context: context,
      heightFactor: 0.62,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AppSheetContent(
          title: const Text('Add Medication / Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAutocompleteField<MedicationItem>(
                options: items,
                labelText: 'Medication / Item',
                hintText: 'Type an item name or code',
                prefixIcon: const Icon(Icons.medication_outlined),
                displayStringForOption: (item) =>
                    '${item.code} — ${item.name} (${_money.format(item.price)})',
                searchStringForOption: (item) =>
                    '${item.code} ${item.name} ${item.unit ?? ''}',
                onSelected: (item) => setModalState(() => selectedItem = item),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () => setModalState(() => quantity--)
                            : null,
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setModalState(() => quantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              variant: AppButtonVariant.primary,
              onPressed: selectedItem == null
                  ? null
                  : () {
                      setState(() {
                        _selectedItems.add(
                          ClaimedItem(item: selectedItem!, quantity: quantity),
                        );
                      });
                      Navigator.pop(ctx);
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
