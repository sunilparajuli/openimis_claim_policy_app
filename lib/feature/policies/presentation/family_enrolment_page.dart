import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/insuree/presentation/insuree_enquiry_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/policy_renewal_page.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';

class FamilyMember {
  final String fullName;
  final String relation; // Head, Spouse, Child, Dependent
  final String gender;
  final String dob;
  final String chfId;

  const FamilyMember({
    required this.fullName,
    required this.relation,
    required this.gender,
    required this.dob,
    required this.chfId,
  });
}

class FamilyRecord {
  final int id;
  final String headName;
  final String headChfId;
  final String region;
  final String district;
  final String ward;
  final String village;
  final String povertyStatus; // Poor / Non-Poor
  final String familyType; // Nuclear / Extended
  final String policyStatus; // Active / Expired / Uninsured
  final String planName;
  final String policyExpiry;
  final List<FamilyMember> members;

  const FamilyRecord({
    required this.id,
    required this.headName,
    required this.headChfId,
    required this.region,
    required this.district,
    required this.ward,
    required this.village,
    required this.povertyStatus,
    required this.familyType,
    required this.policyStatus,
    required this.planName,
    required this.policyExpiry,
    required this.members,
  });
}

class FamilyEnrolmentPage extends ConsumerStatefulWidget {
  const FamilyEnrolmentPage({super.key});

  @override
  ConsumerState<FamilyEnrolmentPage> createState() =>
      _FamilyEnrolmentPageState();
}

class _FamilyEnrolmentPageState extends ConsumerState<FamilyEnrolmentPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FamilyRecord> _families = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNewFamilyDialog() {
    final headController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRegion = 'Central';
    String selectedPoverty = 'Non-Poor';
    String selectedFamilyType = 'Nuclear';

    showAppBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AppSheetContent(
          title: const Text('New Household Enrolment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: headController,
                  decoration: const InputDecoration(
                    labelText: 'Head of Household Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (SMS confirmation)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                AppDropdownField<String>(
                  value: selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    prefixIcon: Icon(Icons.map),
                  ),
                  items:
                      const [
                            'Central',
                            'Rift Valley',
                            'Coast',
                            'Western',
                            'Eastern',
                          ]
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedRegion = val!),
                ),
                const SizedBox(height: 12),
                AppDropdownField<String>(
                  value: selectedPoverty,
                  decoration: const InputDecoration(
                    labelText: 'Poverty Status',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  items: const ['Non-Poor', 'Poor', 'Indigent / Subsidized']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedPoverty = val!),
                ),
                const SizedBox(height: 12),
                AppDropdownField<String>(
                  value: selectedFamilyType,
                  decoration: const InputDecoration(
                    labelText: 'Family Type',
                    prefixIcon: Icon(Icons.group),
                  ),
                  items: const ['Nuclear', 'Extended']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedFamilyType = val!),
                ),
              ],
            ),
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              variant: AppButtonVariant.primary,
              onPressed: () {
                if (headController.text.trim().isEmpty) return;
                final randomId = DateTime.now().millisecondsSinceEpoch % 100000;
                final newChfId = 'CHF-$randomId';
                final newFamily = FamilyRecord(
                  id: _families.length + 1,
                  headName: headController.text.trim(),
                  headChfId: newChfId,
                  region: selectedRegion,
                  district: '$selectedRegion Central',
                  ward: 'Ward 1',
                  village: 'Village Center',
                  povertyStatus: selectedPoverty,
                  familyType: selectedFamilyType,
                  policyStatus: 'Active',
                  planName: 'Universal Health Coverage Plan',
                  policyExpiry: '2027-12-31',
                  members: [
                    FamilyMember(
                      fullName: headController.text.trim(),
                      relation: 'Head of Family',
                      gender: 'Male',
                      dob: '1988-01-01',
                      chfId: newChfId,
                    ),
                  ],
                );
                setState(() => _families.insert(0, newFamily));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: CustomColors.SuccessGreen,
                    content: Text(
                      'Family "${newFamily.headName}" enrolled with card $newChfId',
                    ),
                  ),
                );
              },
              child: const Text('Enrol Family'),
            ),
          ],
        ),
      ),
    );
  }

  Future<FamilyMember?> _showAddFamilyMemberDialog() async {
    final nameController = TextEditingController();
    final chfIdController = TextEditingController();
    String? relationship;
    String? gender;
    DateTime? dateOfBirth;

    final member = await showAppBottomSheet<FamilyMember>(
      context: context,
      heightFactor: 0.72,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => AppSheetContent(
          title: Row(
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Add Family Member / Dependent')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: chfIdController,
                decoration: const InputDecoration(
                  labelText: 'Insuree CHF ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              AppDropdownField<String>(
                value: relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                  DropdownMenuItem(value: 'Child', child: Text('Child')),
                  DropdownMenuItem(
                    value: 'Parent / Dependent',
                    child: Text('Parent / Dependent'),
                  ),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setModalState(() => relationship = value),
              ),
              const SizedBox(height: 12),
              AppDropdownField<String>(
                value: gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setModalState(() => gender = value),
              ),
              const SizedBox(height: 12),
              AppDateField(
                labelText: 'Date of Birth',
                value: dateOfBirth,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onChanged: (value) => setModalState(() => dateOfBirth = value),
              ),
            ],
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(sheetContext),
              label: const Text('Cancel'),
            ),
            AppButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    chfIdController.text.trim().isEmpty ||
                    relationship == null ||
                    gender == null ||
                    dateOfBirth == null) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('Complete all family member fields.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  sheetContext,
                  FamilyMember(
                    fullName: nameController.text.trim(),
                    relation: relationship!,
                    gender: gender!,
                    dob: dateOfBirth!.toIso8601String().substring(0, 10),
                    chfId: chfIdController.text.trim(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    chfIdController.dispose();
    return member;
  }

  void _showFamilyDetailSheet(FamilyRecord family) {
    showAppBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family: ${family.headName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${family.village}, ${family.ward}, ${family.district} (${family.region})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  labelColor: CustomColors.BrandPurple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: CustomColors.BrandPurple,
                  tabs: [
                    Tab(icon: Icon(Icons.group), text: 'Insurees / Dependents'),
                    Tab(
                      icon: Icon(Icons.security),
                      text: 'Policies & Premiums',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Insurees
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...family.members.map(
                            (m) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: CustomColors
                                      .BrandPurple.withValues(alpha: 0.1),
                                  child: Text(
                                    m.fullName.substring(0, 1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: CustomColors.BrandPurple,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  m.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${m.relation} • ${m.gender} • DOB: ${m.dob}',
                                ),
                                trailing: Text(
                                  m.chfId,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const InsureeEnquiryPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            variant: AppButtonVariant.secondary,
                            onPressed: () async {
                              final member = await _showAddFamilyMemberDialog();
                              if (member == null || !mounted) return;
                              setState(() => family.members.add(member));
                              setSheetState(() {});
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  backgroundColor: CustomColors.SuccessGreen,
                                  content: Text(
                                    '${member.fullName} added to the family.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Family Member / Dependent'),
                          ),
                        ],
                      ),

                      // Tab 2: Policies
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        family.planName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (family.policyStatus == 'Active'
                                                      ? CustomColors
                                                            .SuccessGreen
                                                      : CustomColors.NavRed)
                                                  .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          family.policyStatus.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color:
                                                family.policyStatus == 'Active'
                                                ? CustomColors.SuccessGreen
                                                : CustomColors.NavRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Valid Until: ${family.policyExpiry}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Poverty Status: ${family.povertyStatus}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Family Unit Type: ${family.familyType}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const Divider(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: AppButton(
                                      variant: AppButtonVariant.primary,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PolicyRenewalPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.autorenew),
                                      label: const Text(
                                        'Renew / Pay Contribution',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _families.where((f) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return f.headName.toLowerCase().contains(q) ||
          f.headChfId.toLowerCase().contains(q) ||
          f.village.toLowerCase().contains(q) ||
          f.district.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppAppBar(title: const Text('Family & Insuree Enrolment')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppTextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search family by head name, card number, village...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? AppEmptyState(
                    icon: _searchQuery.isEmpty
                        ? Icons.family_restroom_outlined
                        : Icons.search_off_rounded,
                    message: _searchQuery.isEmpty
                        ? 'No enrolled families available'
                        : 'No families match your search',
                    description: _searchQuery.isEmpty
                        ? 'Real family records will appear here after enrolment or synchronization.'
                        : 'Try a different name, card number, or location.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final fam = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: InkWell(
                          onTap: () => _showFamilyDetailSheet(fam),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        fam.headName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AppStatusBadge(
                                      label: fam.policyStatus.toUpperCase(),
                                      tone: fam.policyStatus == 'Active'
                                          ? AppStatusTone.success
                                          : AppStatusTone.danger,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Card: ${fam.headChfId} • ${fam.povertyStatus}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  '${fam.village}, ${fam.district} (${fam.region})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.group,
                                      size: 16,
                                      color: CustomColors.BrandPurple,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${fam.members.length} Household Members',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: CustomColors.BrandPurple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: CustomColors.BrandPurple,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewFamilyDialog,
        backgroundColor: CustomColors.BrandPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Enrol Family'),
      ),
    );
  }
}
