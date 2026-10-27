import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/config/currency_provider.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/app_providers/app_provider.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claim_wizard_page.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';

enum ClaimStatusTab {
  entered('Entered / Pending', Colors.orange),
  accepted('Accepted', CustomColors.SuccessGreen),
  rejected('Rejected', CustomColors.NavRed);

  final String label;
  final Color color;
  const ClaimStatusTab(this.label, this.color);
}

class ClaimItemRecord {
  final String claimCode;
  final String insureeName;
  final String insureeChfId;
  final String healthFacility;
  final String date;
  final ClaimStatusTab status;
  final double totalAmount;
  final String primaryDiagnosis;
  final String? rejectionReason;
  final List<String> services;
  final List<String> medications;

  const ClaimItemRecord({
    required this.claimCode,
    required this.insureeName,
    required this.insureeChfId,
    required this.healthFacility,
    required this.date,
    required this.status,
    required this.totalAmount,
    required this.primaryDiagnosis,
    this.rejectionReason,
    this.services = const [],
    this.medications = const [],
  });
}

class ClaimsListingPage extends ConsumerStatefulWidget {
  const ClaimsListingPage({super.key});

  @override
  ConsumerState<ClaimsListingPage> createState() => _ClaimsListingPageState();
}

class _ClaimsListingPageState extends ConsumerState<ClaimsListingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchQuery = '';

  static const List<ClaimItemRecord> _demoClaims = [
    ClaimItemRecord(
      claimCode: 'CLM-78401',
      insureeName: 'Amina Mwangi',
      insureeChfId: 'CHF-9823412',
      healthFacility: 'St. Mary Referral Hospital',
      date: '2026-10-08',
      status: ClaimStatusTab.entered,
      totalAmount: 48.50,
      primaryDiagnosis: 'A09 - Gastroenteritis and colitis, unspecified',
      services: ['General Consultation', 'Blood Analysis Routine'],
      medications: ['Amoxicillin 500mg (2x)', 'Oral Rehydration Salts (3x)'],
    ),
    ClaimItemRecord(
      claimCode: 'CLM-78402',
      insureeName: 'Joseph Kiptoo',
      insureeChfId: 'CHF-7749102',
      healthFacility: 'District Central Clinic',
      date: '2026-10-07',
      status: ClaimStatusTab.entered,
      totalAmount: 120.00,
      primaryDiagnosis: 'J18 - Pneumonia, organism unspecified',
      services: ['Emergency Care', 'Chest X-Ray Single View'],
      medications: ['Azithromycin 250mg', 'Paracetamol 500mg'],
    ),
    ClaimItemRecord(
      claimCode: 'CLM-78390',
      insureeName: 'Fatuma Hassan',
      insureeChfId: 'CHF-6623091',
      healthFacility: 'St. Mary Referral Hospital',
      date: '2026-10-05',
      status: ClaimStatusTab.accepted,
      totalAmount: 75.00,
      primaryDiagnosis: 'B50 - Plasmodium falciparum malaria',
      services: ['Malaria Rapid Test', 'Observation Care (12h)'],
      medications: ['Artemether-Lumefantrine 80/480mg', 'Paracetamol 500mg'],
    ),
    ClaimItemRecord(
      claimCode: 'CLM-78385',
      insureeName: 'Samuel Odhiambo',
      insureeChfId: 'CHF-5519820',
      healthFacility: 'Regional General Hospital',
      date: '2026-10-03',
      status: ClaimStatusTab.accepted,
      totalAmount: 340.00,
      primaryDiagnosis: 'K35 - Acute appendicitis',
      services: ['Emergency Appendectomy', 'Inpatient Ward (3 days)'],
      medications: [
        'Ceftriaxone 1g IV',
        'Metronidazole 500mg IV',
        'Tramadol 50mg',
      ],
    ),
    ClaimItemRecord(
      claimCode: 'CLM-78350',
      insureeName: 'Grace Muthoni',
      insureeChfId: 'CHF-4401923',
      healthFacility: 'Sunrise Health Centre',
      date: '2026-10-01',
      status: ClaimStatusTab.rejected,
      totalAmount: 62.00,
      primaryDiagnosis: 'Z00 - General adult medical examination',
      rejectionReason:
          'Routine health checkup not covered under Standard Care Policy NHIF-STD-2026.',
      services: ['Executive Health Screening'],
      medications: ['Multivitamin syrup'],
    ),
    ClaimItemRecord(
      claimCode: 'CLM-78342',
      insureeName: 'David Njoroge',
      insureeChfId: 'CHF-3391824',
      healthFacility: 'District Central Clinic',
      date: '2026-09-28',
      status: ClaimStatusTab.rejected,
      totalAmount: 180.00,
      primaryDiagnosis: 'E11 - Type 2 diabetes mellitus without complications',
      rejectionReason: 'Exceeded outpatient annual benefit ceiling.',
      services: [
        'Specialist Endocrine Consultation',
        'HbA1c Glycated Hemoglobin Test',
      ],
      medications: ['Metformin 850mg (90 tabs)'],
    ),
  ];
  late final List<ClaimItemRecord> _allClaims;

  MoneyFormatter get _money => ref.read(moneyFormatterProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ClaimStatusTab.values.length,
      vsync: this,
    );
    _allClaims = ref.read(appProvider).demoMode ? _demoClaims : const [];
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(Duration.zero);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ClaimItemRecord> _getFilteredClaims(ClaimStatusTab status) {
    return _allClaims.where((c) {
      if (c.status != status) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.claimCode.toLowerCase().contains(q) ||
          c.insureeName.toLowerCase().contains(q) ||
          c.insureeChfId.toLowerCase().contains(q) ||
          c.primaryDiagnosis.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(moneyFormatterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: Text(context.tr('Claims Listing')),
        bottom: TabBar(
          controller: _tabController,
          // Status labels and counts must retain their natural width on phones
          // and with larger accessibility text rather than sharing fixed thirds.
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: ClaimStatusTab.values.map((tab) {
            final count = _allClaims.where((c) => c.status == tab).length;
            return Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.tr(tab.label).toUpperCase()),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppTextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr(
                  'Search by Claim Code, Insurance No, or Patient Name',
                ),
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

          // Tab content
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ClaimListShimmer(count: 4),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: ClaimStatusTab.values.map((tab) {
                      final claims = _getFilteredClaims(tab);
                      if (claims.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('No ${tab.label} Claims Found'),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: claims.length,
                          itemBuilder: (context, index) {
                            final claim = claims[index];
                            return _buildClaimCard(claim, theme);
                          },
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClaimWizardPage()),
          );
        },
        backgroundColor: CustomColors.BrandPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr('New Claim')),
      ),
    );
  }

  Widget _buildClaimCard(ClaimItemRecord claim, ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _showClaimDetailsModal(claim),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    claim.claimCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: CustomColors.BrandPurple,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: claim.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.tr(claim.status.label).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: claim.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    claim.insureeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${claim.insureeChfId})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.local_hospital_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      claim.healthFacility,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Text(
                    claim.date,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Dx: ${claim.primaryDiagnosis}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money.format(claim.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CustomColors.BrandPurple,
                    ),
                  ),
                ],
              ),
              if (claim.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          claim.rejectionReason!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClaimDetailsModal(ClaimItemRecord claim) {
    showAppBottomSheet(
      context: context,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.claimCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.tr('openIMIS FHIR Claim Review'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: claim.status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.tr(claim.status.label).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: claim.status.color,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _detailRow(context.tr('Insuree Name'), claim.insureeName),
                  _detailRow(context.tr('Insurance No'), claim.insureeChfId),
                  _detailRow(
                    context.tr('Health Facility'),
                    claim.healthFacility,
                  ),
                  _detailRow(context.tr('Date of Submission'), claim.date),
                  _detailRow(context.tr('Main Dg'), claim.primaryDiagnosis),
                  _detailRow(
                    context.tr('Total Claimed'),
                    _money.format(claim.totalAmount),
                  ),
                  if (claim.rejectionReason != null)
                    _detailRow(
                      context.tr('Rejection Reason'),
                      claim.rejectionReason!,
                      isAlert: true,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('Services:'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...claim.services.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: CustomColors.BrandPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(s, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('Medications & Consumables:'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...claim.medications.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medication,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(m, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isAlert ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
