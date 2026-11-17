import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/core/utils/insuree_number.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/offline_insuree_update.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/policies/repositories/policy_enrollment_repository.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/csu_master_data_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';

class HivInsureeEditForm extends ConsumerStatefulWidget {
  const HivInsureeEditForm({super.key});

  @override
  ConsumerState<HivInsureeEditForm> createState() => _HivInsureeEditFormState();
}

class _HivInsureeEditFormState extends ConsumerState<HivInsureeEditForm> {
  final _mpi = TextEditingController();
  PolicyInsureeDraft? _insuree;
  String? _gender;
  DateTime? _dateOfBirth;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _mpi.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final mpi = InsureeNumber.normalize(_mpi.text);
    if (InsureeNumber.validate(mpi) != null) {
      setState(() => _error = context.tr('A valid MPI/CHFID is required.'));
      return;
    }
    if (RegExp(r'^\d+$').hasMatch(mpi)) {
      setState(
        () => _error = context.tr(
          'An HIV beneficiary MPI cannot contain only numbers.',
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final insuree = await ref
          .read(policyEnrollmentRepositoryProvider)
          .insureeForEdit(mpi, application: PolicyApplication.hiv);
      if (!mounted) return;
      setState(() {
        _insuree = insuree;
        _gender = insuree.genderId;
        _dateOfBirth = insuree.dateOfBirth;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.toString().replaceFirst('FormatException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _save() {
    final insuree = _insuree;
    final gender = _gender;
    final dob = _dateOfBirth;
    if (insuree == null || gender == null || dob == null) return;
    final now = DateTime.now().toUtc();
    Navigator.pop(
      context,
      OfflineInsureeUpdate(
        id: 'hiv-update-${insuree.uuid}-${now.microsecondsSinceEpoch}',
        application: PolicyApplication.hiv,
        insuree: insuree.withDemographics(genderId: gender, dateOfBirth: dob),
        createdAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(csuMasterDataProvider).value?.data;
    final genders = data?.records('genders') ?? const [];
    return AppSheetContent(
      title: Text(context.tr('Edit HIV beneficiary')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _mpi,
              enabled: _insuree == null && !_loading,
              decoration: InputDecoration(
                labelText: context.tr('TARV / MPI number'),
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 12),
            if (_insuree == null)
              AppButton(
                expanded: true,
                onPressed: _loading ? null : _load,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(context.tr('Find beneficiary')),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_insuree != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_insuree!.otherNames} ${_insuree!.lastName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
            ],
          ],
        ),
      ),
      actions: [
        AppButton(
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(context),
          label: Text(context.tr('Cancel')),
        ),
        if (_insuree != null)
          AppButton(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(context.tr('Save offline')),
          ),
      ],
    );
  }
}
