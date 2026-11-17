import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/core/utils/insuree_number.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/offline_policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_cheque.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_product.dart';
import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/csu_input_limits_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/csu_master_data_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';

class PolicyEnrollmentFormResult {
  const PolicyEnrollmentFormResult({
    required this.enrollment,
    required this.headName,
    required this.locationName,
    required this.productName,
  });

  final OfflinePolicyEnrollment enrollment;
  final String headName;
  final String locationName;
  final String productName;
}

class PolicyEnrollmentForm extends ConsumerStatefulWidget {
  const PolicyEnrollmentForm({required this.application, super.key});

  final PolicyApplication application;

  @override
  ConsumerState<PolicyEnrollmentForm> createState() =>
      _PolicyEnrollmentFormState();
}

class _PolicyEnrollmentFormState extends ConsumerState<PolicyEnrollmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _mpi = TextEditingController();
  final _lastName = TextEditingController();
  final _otherNames = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _value = TextEditingController();
  final _cheque = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  String? _gender;
  String? _familyType;
  int? _locationId;
  int? _officerId;
  int? _productId;
  int? _pregnancyWeek;
  bool _poverty = false;

  @override
  void dispose() {
    _mpi.dispose();
    _lastName.dispose();
    _otherNames.dispose();
    _phone.dispose();
    _address.dispose();
    _value.dispose();
    _cheque.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(csuMasterDataProvider).value;
    if (snapshot == null) {
      return AppSheetContent(
        title: Text(context.tr('Master data required')),
        content: Text(
          context.tr('Synchronize master data before enrolling a beneficiary.'),
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            label: Text(context.tr('Close')),
          ),
        ],
      );
    }
    final data = snapshot.data;
    final locations = data
        .records('locations')
        .where((record) => record.id != null)
        .toList(growable: false);
    final officers = data
        .records('officers')
        .where((record) => record.id != null)
        .toList(growable: false);
    final products = _products(data);
    final genders = data.records('genders');
    final familyTypes = data.records('familyTypes');
    final selectedProduct = products
        .where((product) => product.id == _productId)
        .firstOrNull;

    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      child: AppSheetContent(
        title: Text(
          widget.application == PolicyApplication.hiv
              ? context.tr('New HIV beneficiary')
              : context.tr('New CSU household'),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _mpi,
                  decoration: InputDecoration(
                    labelText: widget.application == PolicyApplication.hiv
                        ? context.tr('TARV / MPI number')
                        : context.tr('MPI / CHFID'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: _validateMpi,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _lastName,
                  decoration: InputDecoration(
                    labelText: context.tr('Last name'),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _otherNames,
                  decoration: InputDecoration(
                    labelText: context.tr('Other names'),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppDropdownField<String>(
                  value: _gender,
                  decoration: InputDecoration(labelText: context.tr('Gender')),
                  items: genders
                      .where((record) => record.code != null)
                      .map(
                        (record) => DropdownMenuItem(
                          value: record.code,
                          child: Text(record.name ?? record.code!),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _gender = value),
                ),
                const SizedBox(height: 12),
                AppDateField(
                  labelText: context.tr('Date of Birth'),
                  value: _dateOfBirth,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  onChanged: (value) => setState(() => _dateOfBirth = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: context.tr('Phone')),
                ),
                const SizedBox(height: 12),
                AppDropdownField<int>(
                  value: _locationId,
                  decoration: InputDecoration(
                    labelText: context.tr('Location'),
                  ),
                  items: locations
                      .map(
                        (record) => DropdownMenuItem(
                          value: record.id,
                          child: Text(
                            record.name ?? record.code ?? '${record.id}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _locationId = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _address,
                  decoration: InputDecoration(labelText: context.tr('Address')),
                ),
                if (widget.application == PolicyApplication.csu) ...[
                  const SizedBox(height: 12),
                  AppDropdownField<String>(
                    value: _familyType,
                    decoration: InputDecoration(
                      labelText: context.tr('Family Type'),
                    ),
                    items: familyTypes
                        .where((record) => record.code != null)
                        .map(
                          (record) => DropdownMenuItem(
                            value: record.code,
                            child: Text(record.name ?? record.code!),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _familyType = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('Poor / subsidized household')),
                    value: _poverty,
                    onChanged: (value) => setState(() => _poverty = value),
                  ),
                ],
                const Divider(height: 28),
                AppDropdownField<int>(
                  value: _productId,
                  decoration: InputDecoration(labelText: context.tr('Product')),
                  items: products
                      .map(
                        (product) => DropdownMenuItem(
                          value: product.id,
                          child: Text(product.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() {
                    _productId = value;
                    _pregnancyWeek = null;
                    _cheque.clear();
                  }),
                ),
                const SizedBox(height: 12),
                AppDropdownField<int>(
                  value: _officerId,
                  decoration: InputDecoration(
                    labelText: context.tr('Enrolment officer'),
                  ),
                  items: officers
                      .map(
                        (record) => DropdownMenuItem(
                          value: record.id,
                          child: Text(_officerName(record)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _officerId = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('Policy value'),
                  ),
                  validator: (value) => num.tryParse(value ?? '') == null
                      ? context.tr('Enter a valid policy value')
                      : null,
                ),
                const SizedBox(height: 12),
                AppDateField(
                  labelText: context.tr('Policy start date'),
                  value: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  onChanged: (value) => setState(() => _startDate = value),
                ),
                const SizedBox(height: 12),
                AppDateField(
                  labelText: context.tr('Requested expiry date'),
                  value: _expiryDate,
                  firstDate: _startDate,
                  lastDate: DateTime(2100),
                  onChanged: (value) => setState(() => _expiryDate = value),
                ),
                if (selectedProduct?.isChequeSante == true) ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _cheque,
                    decoration: InputDecoration(
                      labelText: context.tr('Cheque number'),
                    ),
                    validator: (value) => ref
                        .read(csuInputLimitsProvider)
                        .validateCheque(value?.trim() ?? ''),
                  ),
                  const SizedBox(height: 12),
                  AppDropdownField<int>(
                    value: _pregnancyWeek,
                    decoration: InputDecoration(
                      labelText: context.tr('Pregnancy week'),
                    ),
                    items: List.generate(
                      42,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _pregnancyWeek = value),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(context),
            label: Text(context.tr('Cancel')),
          ),
          AppButton(
            onPressed: () => _submit(data, products, locations),
            icon: const Icon(Icons.save_outlined),
            label: Text(context.tr('Save offline')),
          ),
        ],
      ),
    );
  }

  List<PolicyProduct> _products(CsuMasterData data) {
    final result = <PolicyProduct>[];
    for (final record in data.products) {
      try {
        final product = PolicyProduct.fromMasterData(
          record,
          programs: data.programs,
        );
        final isHiv = product.isHiv;
        if ((widget.application == PolicyApplication.hiv && isHiv) ||
            (widget.application == PolicyApplication.csu && !isHiv)) {
          result.add(product);
        }
      } on FormatException {
        // Products without server IDs cannot be synchronized and are hidden.
      }
    }
    return result;
  }

  String? _required(String? value) => value?.trim().isEmpty != false
      ? context.tr('This field is required')
      : null;

  String? _validateMpi(String? value) {
    final normalized = InsureeNumber.normalize(value ?? '');
    final structural = InsureeNumber.validate(normalized);
    if (structural != null) return context.tr('Enter a valid MPI / CHFID');
    final length = ref.read(csuInputLimitsProvider).validateMpi(normalized);
    if (length != null) return context.tr(length);
    if (widget.application == PolicyApplication.hiv &&
        RegExp(r'^\d+$').hasMatch(normalized)) {
      return context.tr('HIV MPI cannot contain only numbers');
    }
    return null;
  }

  void _submit(
    CsuMasterData data,
    List<PolicyProduct> products,
    List<CsuMasterDataRecord> locations,
  ) {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null ||
        _dateOfBirth == null ||
        _locationId == null ||
        _officerId == null ||
        _productId == null) {
      _warning(context.tr('Complete all required dropdowns and dates.'));
      return;
    }
    final product = products.firstWhere((item) => item.id == _productId);
    if (product.isChequeSante && _pregnancyWeek == null) {
      _warning(context.tr('Pregnancy week is required.'));
      return;
    }
    if (product.isChequeSante) {
      final chequeIssue = PolicyCheque.validate(_cheque.text, data.cheques);
      if (chequeIssue != null) {
        _warning(context.tr(chequeIssue));
        return;
      }
    }
    final eligibility = product.eligibility(_dateOfBirth!, _startDate);
    if (!eligibility.allowed) {
      _warning(context.tr(eligibility.message!));
      return;
    }
    final expiry = product.cappedExpiry(_dateOfBirth!, _startDate, _expiryDate);
    final head = PolicyInsureeDraft(
      chfId: InsureeNumber.normalize(_mpi.text),
      lastName: _lastName.text.trim(),
      otherNames: _otherNames.text.trim(),
      genderId: _gender!,
      dateOfBirth: _dateOfBirth!,
      isHead: true,
      phone: _phone.text.trim(),
      currentAddress: _address.text.trim(),
      currentVillageId: _locationId,
    );
    final now = DateTime.now();
    final id = '${widget.application.name}-${now.microsecondsSinceEpoch}';
    final enrollment = OfflinePolicyEnrollment(
      id: id,
      family: PolicyFamilyDraft(
        application: widget.application,
        locationId: _locationId!,
        head: head,
        poverty: _poverty,
        familyTypeId: _familyType,
        address: _address.text.trim(),
      ),
      members: const [],
      policies: [
        PolicyDraft(
          familyId: 0,
          enrolmentDate: now,
          startDate: _startDate,
          expiryDate: expiry,
          value: num.parse(_value.text),
          productId: product.id,
          officerId: _officerId!,
          productCode: product.code,
          policyNumber: product.isChequeSante ? _cheque.text.trim() : null,
          pregnancyAge: product.isChequeSante ? _pregnancyWeek : null,
          isChequeSante: product.isChequeSante,
        ),
      ],
      createdAt: now,
    );
    final location = locations.firstWhere((record) => record.id == _locationId);
    Navigator.pop(
      context,
      PolicyEnrollmentFormResult(
        enrollment: enrollment,
        headName: '${head.otherNames} ${head.lastName}'.trim(),
        locationName: location.name ?? location.code ?? '',
        productName: product.name,
      ),
    );
  }

  void _warning(String message) {
    showAppFeedbackDialog(
      context: context,
      type: AppFeedbackType.warning,
      message: message,
    );
  }

  static String _officerName(CsuMasterDataRecord record) {
    final names = [
      record.values['OtherNames'],
      record.values['LastName'],
    ].whereType<Object>().map((value) => value.toString()).join(' ').trim();
    return names.isNotEmpty ? names : record.code ?? '${record.id}';
  }
}
