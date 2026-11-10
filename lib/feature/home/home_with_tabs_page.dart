import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claim_setup_flow.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claim_wizard_page.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claims_listing_page.dart';
import 'package:openimis_claim_policy_app/feature/home/home_page.dart';
import 'package:openimis_claim_policy_app/feature/home/profile_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/family_enrolment_page.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_bottom_navigation.dart';

@RoutePage()
class HomeWithTabsPage extends ConsumerStatefulWidget {
  const HomeWithTabsPage({super.key});

  @override
  ConsumerState<HomeWithTabsPage> createState() => _HomeWithTabsPageState();
}

class _HomeWithTabsPageState extends ConsumerState<HomeWithTabsPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = const [
    HomePage(title: 'Home'),
    ClaimsListingPage(),
    FamilyEnrolmentPage(),
    ProfilePage(title: 'Profile'),
  ];

  Future<void> _selectNavigationItem(int index) async {
    if (index == 2) {
      await _openNewClaim();
      return;
    }

    final pageIndex = index > 2 ? index - 1 : index;
    if (pageIndex == 1 &&
        !await ensureClaimAdministratorConfigured(context, ref)) {
      return;
    }

    if (mounted) setState(() => _selectedIndex = pageIndex);
  }

  Future<void> _openNewClaim() async {
    if (await ensureClaimAdministratorConfigured(context, ref) && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClaimWizardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = [
      AppBottomNavigationItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: context.tr('Home'),
      ),
      AppBottomNavigationItem(
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment_rounded,
        label: context.tr('Claims'),
      ),
      AppBottomNavigationItem(
        icon: Icons.add_box_outlined,
        selectedIcon: Icons.add_box_rounded,
        label: context.tr('New Claim'),
        isAction: true,
      ),
      AppBottomNavigationItem(
        icon: Icons.family_restroom_outlined,
        selectedIcon: Icons.family_restroom_rounded,
        label: context.tr('Enrolment'),
      ),
      AppBottomNavigationItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: context.tr('Profile'),
      ),
    ];
    final navigationIndex = _selectedIndex >= 2
        ? _selectedIndex + 1
        : _selectedIndex;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          _pages.length,
          (index) =>
              HeroMode(enabled: index == _selectedIndex, child: _pages[index]),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: navigationIndex,
        items: navigationItems,
        onTap: _selectNavigationItem,
      ),
    );
  }
}
