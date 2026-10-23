import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/core/localization/language_selector_widget.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claim_wizard_page.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claim_setup_flow.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claims_listing_page.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/offline_claims_sheet.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/service_item_catalog_page.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/offline_claim_repository.dart';
import 'package:openimis_claim_policy_app/feature/insuree/presentation/insuree_enquiry_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/family_enrolment_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/feedback_survey_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/indicators_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/policy_renewal_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/reports_overview_page.dart';
import 'package:openimis_claim_policy_app/feature/shared/navigation/app_router.gr.dart';
import 'package:openimis_claim_policy_app/feature/shared/presentation/about_openimis_page.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';

@RoutePage()
class HomePage extends ConsumerStatefulWidget {
  const HomePage({required this.title, super.key});
  final String title;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pendingClaimsCount = ref.watch(pendingClaimsCountProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/openimis-logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.health_and_safety, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(l10n.appTitle, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          const LanguageSelectorButton(),
          Semantics(
            identifier: 'home_settings_button',
            label: context.tr('Settings'),
            button: true,
            child: IconButton(
              onPressed: () => context.router.push(const SettingsRoute()),
              icon: const Icon(Icons.settings_outlined),
              tooltip: context.tr('Settings'),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, l10n),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Card
          Semantics(
            identifier: 'home_welcome_card',
            label: '${l10n.welcomeBack} ${l10n.welcomeSubtitle}',
            explicitChildNodes: true,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.welcomeBack,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Semantics(
                            identifier: 'home_welcome_subtitle',
                            label: l10n.welcomeSubtitle,
                            child: Text(
                              l10n.welcomeSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dashboard summaries from the two Java home layouts.
          _buildKpiDashboard(context),

          const SizedBox(height: 20),

          // Offline Claims Storage & Sync Card
          Semantics(
            identifier: 'home_feature_offline_sync',
            label: context.tr('Synchronize'),
            button: true,
            child: Card(
              color: pendingClaimsCount > 0
                  ? CustomColors.BrandPurple.withValues(alpha: 0.08)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: pendingClaimsCount > 0
                      ? CustomColors.BrandPurple.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: InkWell(
                onTap: () async {
                  if (await ensureClaimAdministratorConfigured(context, ref) &&
                      context.mounted) {
                    OfflineClaimsSheet.show(context);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: pendingClaimsCount > 0
                              ? CustomColors.BrandPurple.withValues(alpha: 0.15)
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Badge(
                          isLabelVisible: pendingClaimsCount > 0,
                          label: Text('$pendingClaimsCount'),
                          backgroundColor: CustomColors.ExpiryOrange,
                          child: Icon(
                            pendingClaimsCount > 0
                                ? Icons.cloud_sync_rounded
                                : Icons.storage_rounded,
                            color: CustomColors.BrandPurple,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.isFrench
                                      ? 'Synchroniser'
                                      : context.tr('Synchronize'),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (pendingClaimsCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CustomColors
                                          .ExpiryOrange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$pendingClaimsCount ${l10n.isFrench ? "en attente" : "pending"}',
                                      style: const TextStyle(
                                        color: CustomColors.ExpiryOrange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pendingClaimsCount > 0
                                  ? (l10n.isFrench
                                        ? 'Prestations en attente. Appuyez pour synchroniser.'
                                        : 'Claims waiting to upload. Tap to synchronize.')
                                  : (l10n.isFrench
                                        ? 'Aucune prestation en attente.'
                                        : 'No claims waiting to upload.'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: Core Operations
          _buildSectionHeader(
            context,
            icon: Icons.verified_user_outlined,
            title: l10n.isFrench
                ? 'Vérification & Prestations'
                : 'Verification & Claims',
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_insuree_enquiry',
            icon: Icons.person_search_rounded,
            title: l10n.insureeVerificationTitle,
            description: l10n.isFrench
                ? 'Vérifier statut, soldes et plafonds de prestations (CIM-10)'
                : 'Verify policy status, benefit limits, and remaining balances',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InsureeEnquiryPage()),
            ),
            isHighlighted: true,
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_claims_listing',
            icon: Icons.list_alt_rounded,
            title: l10n.isFrench
                ? 'Gestion des Prestations (Listing)'
                : 'Claims Listing & Adjudication',
            description: l10n.isFrench
                ? 'Visualiser les prestations soumises, acceptées et rejetées'
                : 'Browse entered, accepted, and rejected claims with review details',
            onTap: () async {
              if (await ensureClaimAdministratorConfigured(context, ref) &&
                  context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClaimsListingPage()),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_claim_wizard',
            icon: Icons.assignment_turned_in_rounded,
            title: l10n.newClaimFormTitle,
            description: l10n.isFrench
                ? 'Assistant en 5 étapes : diagnostics CIM-10, prestations et articles'
                : 'Multi-step claim wizard with diagnoses, services, and medications',
            onTap: () async {
              if (await ensureClaimAdministratorConfigured(context, ref) &&
                  context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClaimWizardPage()),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_map_services',
            icon: Icons.category_outlined,
            title: l10n.isFrench
                ? 'Catalogue Prestations & Médicaments'
                : 'Services & Items Catalog Mapping',
            description: l10n.isFrench
                ? 'Activer ou désactiver les prestations et articles pour la structure'
                : 'Map available healthcare services and medications for your health facility',
            onTap: () async {
              if (await ensureClaimAdministratorConfigured(context, ref) &&
                  context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceItemCatalogPage(),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // Section 2: Policies, Enrolment & Field Audit
          _buildSectionHeader(
            context,
            icon: Icons.groups_outlined,
            title: l10n.isFrench
                ? 'Polices, Familles & Audit'
                : 'Policies, Households & Audit',
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_family_enrolment',
            icon: Icons.family_restroom_rounded,
            title: l10n.isFrench
                ? 'Enrôlement des Familles & Ayants Droit'
                : 'Household & Family Enrolment',
            description: l10n.isFrench
                ? 'Enregistrer de nouveaux ménages, chefs de famille et dépendants'
                : 'Register new households, heads of family, and dependents with CHF cards',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilyEnrolmentPage()),
            ),
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_policy_renewal',
            icon: Icons.autorenew_rounded,
            title: l10n.policyRenewalTitle,
            description: l10n.isFrench
                ? 'Renouveler les polices et calculer les cotisations'
                : 'Renew insurance policies and calculate contribution payments',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PolicyRenewalPage()),
            ),
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_feedback',
            icon: Icons.rate_review_outlined,
            title: l10n.isFrench
                ? 'Audit & Retour Bénéficiaire'
                : 'Beneficiary Feedback & Audit',
            description: l10n.isFrench
                ? 'Enquête de satisfaction, vérification de soins et signalement de pots-de-vin'
                : 'Field quality audits, care satisfaction survey, and informal payment reporting',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackSurveyPage()),
            ),
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_indicators',
            icon: Icons.insights_rounded,
            title: l10n.isFrench ? 'Rapports' : context.tr('Reports'),
            description: l10n.isFrench
                ? 'Indicateurs instantanés et cumulés : familles actives, polices échues'
                : 'Policy status snapshots and cumulative policy counts by reporting period',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IndicatorsPage()),
            ),
          ),
          const SizedBox(height: 10),

          _buildFeatureCard(
            context,
            semanticsId: 'home_feature_reports',
            icon: Icons.pie_chart_outline_rounded,
            title: l10n.isFrench
                ? 'Vérifier la commission'
                : context.tr('Check Commission'),
            description: l10n.isFrench
                ? 'Consultation des commissions et rapports sur les polices'
                : 'Officer commission lookup, snapshot reports and cumulative indicators',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsOverviewPage()),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Labels mirror Claims content_main.xml and Policies home_content.xml.
  // Server/local policy totals are not yet connected; never present demo counts as data.
  Widget _buildKpiDashboard(BuildContext context) {
    final metrics = [
      (
        context.tr('Accepted'),
        Icons.check_circle_outline,
        CustomColors.SuccessGreen,
      ),
      (context.tr('Rejected'), Icons.cancel_outlined, CustomColors.NavRed),
      (
        context.tr('Pending'),
        Icons.pending_actions_outlined,
        CustomColors.ExpiryOrange,
      ),
      (
        context.tr('Total Families'),
        Icons.family_restroom,
        CustomColors.BrandPurple,
      ),
      (
        context.tr('Edited Families'),
        Icons.edit_outlined,
        CustomColors.BrandPurple,
      ),
      (
        context.tr('Total Insurees'),
        Icons.people_outline,
        CustomColors.BrandPurple,
      ),
      (
        context.tr('Edited Insurees'),
        Icons.person_outline,
        CustomColors.BrandPurple,
      ),
      (
        context.tr('Total Policies'),
        Icons.policy_outlined,
        CustomColors.BrandPurple,
      ),
      (
        context.tr('Total Contributions'),
        Icons.payments_outlined,
        CustomColors.SuccessGreen,
      ),
      (
        context.tr('Total Amount'),
        Icons.account_balance_wallet_outlined,
        CustomColors.SuccessGreen,
      ),
    ];
    return ExpansionTile(
      key: const PageStorageKey('home_dashboard'),
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.dashboard_outlined),
      title: Text(
        context.tr('Dashboard'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      children: [
        const SizedBox(height: 8),
        for (var row = 0; row < metrics.length; row += 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < 3; column++) ...[
                  if (column > 0) const SizedBox(width: 8),
                  Expanded(
                    child: row + column >= metrics.length
                        ? const SizedBox.shrink()
                        : Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    metrics[row + column].$2,
                                    color: metrics[row + column].$3,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    metrics[row + column].$1,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '—',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: metrics[row + column].$3,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        Text(
          context.tr(
            '— Totals are not available until reporting data is connected.',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: CustomColors.BrandPurple, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: CustomColors.BrandPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: CustomColors.BrandPurple),
            accountName: Text(
              l10n.appTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(context.tr('Claims & Policies')),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/openimis-logo.png',
                height: 36,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.local_hospital,
                  color: CustomColors.BrandPurple,
                ),
              ),
            ),
          ),

          // Drawer Navigation
          ListTile(
            dense: true,
            leading: const Icon(Icons.dashboard_outlined),
            title: Text(
              context.tr('Dashboard'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () => Navigator.pop(context),
          ),

          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              context.tr('CLAIMS MANAGEMENT'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          ListTile(
            dense: true,
            leading: const Icon(Icons.list_alt_rounded),
            title: Text(
              context.tr('Claims Listing'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () async {
              Navigator.pop(context);
              if (await ensureClaimAdministratorConfigured(context, ref) &&
                  context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClaimsListingPage()),
                );
              }
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.add_task_rounded),
            title: Text(
              context.tr('New Claim Form'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () async {
              Navigator.pop(context);
              if (await ensureClaimAdministratorConfigured(context, ref) &&
                  context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClaimWizardPage()),
                );
              }
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.category_outlined),
            title: Text(
              context.tr('Services & Items Mapping'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () async {
              Navigator.pop(context);
              if (await ensureClaimAdministratorConfigured(context, ref) &&
                  context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceItemCatalogPage(),
                  ),
                );
              }
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(
              context.tr('Synchronize'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () async {
              Navigator.pop(context);
              if (await ensureClaimAdministratorConfigured(context, ref) &&
                  context.mounted) {
                OfflineClaimsSheet.show(context);
              }
            },
          ),

          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              context.tr('POLICIES & ENROLMENT'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.family_restroom_rounded),
            title: Text(context.tr('Household Enrolment')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyEnrolmentPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_search_rounded),
            title: Text(context.tr('Insuree & Policy Enquiry')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InsureeEnquiryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.autorenew_rounded),
            title: Text(context.tr('Policy Renewal')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PolicyRenewalPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: Text(context.tr('Beneficiary Audit Survey')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackSurveyPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights_rounded),
            title: Text(context.tr('Reports')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IndicatorsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline_rounded),
            title: Text(context.tr('Check Commission')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsOverviewPage()),
              );
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(context.tr('Settings')),
            onTap: () {
              Navigator.pop(context);
              context.router.push(const SettingsRoute());
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.tr('About openIMIS')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutOpenImisPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String semanticsId,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Semantics(
      identifier: semanticsId,
      label: title,
      button: true,
      child: Card(
        elevation: isHighlighted ? 4 : null,
        color: isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2)
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
