import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claim_setup_flow.dart';
import 'package:openimis_claim_policy_app/feature/claims/presentation/claims_listing_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/presentation/family_enrolment_page.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/shared/models/csu_capabilities.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/csu_master_data_provider.dart';

class CsuWorkspacePanel extends ConsumerWidget {
  const CsuWorkspacePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(csuMasterDataProvider);
    final snapshot = state.value;
    final data = snapshot?.data;
    final capabilities = data == null
        ? null
        : CsuCapabilities.fromMasterData(data);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('CSU Cameroon workspace'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Synchronize master data'),
                  onPressed: state.isLoading
                      ? null
                      : () => ref
                            .read(csuMasterDataProvider.notifier)
                            .synchronize(),
                  icon: state.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_statusText(context, state)),
            if (data != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountChip(
                    label: context.tr('Products'),
                    count: data.products.length,
                  ),
                  _CountChip(
                    label: context.tr('Programs'),
                    count: data.programs.length,
                  ),
                  _CountChip(
                    label: context.tr('Facilities'),
                    count: data.records('hf').length,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Available applications'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (capabilities!.claims)
                _WorkflowTile(
                  icon: Icons.assignment_outlined,
                  title: context.tr('Claims'),
                  subtitle: context.tr('Enter and synchronize medical claims'),
                  onTap: () async {
                    if (await ensureClaimAdministratorConfigured(
                          context,
                          ref,
                        ) &&
                        context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClaimsListingPage(),
                        ),
                      );
                    }
                  },
                ),
              if (capabilities.policiesCsu)
                _WorkflowTile(
                  icon: Icons.family_restroom_outlined,
                  title: context.tr('Policies CSU'),
                  subtitle: context.tr('Enroll families and beneficiaries'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FamilyEnrolmentPage(),
                    ),
                  ),
                ),
              if (capabilities.policiesHiv)
                _WorkflowTile(
                  icon: Icons.health_and_safety_outlined,
                  title: context.tr('Policies HIV'),
                  subtitle: context.tr('HIV workflow detected in master data'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FamilyEnrolmentPage(
                        application: PolicyApplication.hiv,
                      ),
                    ),
                  ),
                ),
            ],
            if (state.hasError) ...[
              const SizedBox(height: 10),
              Text(
                context.tr('Master data is not available. Tap sync to retry.'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText(BuildContext context, AsyncValue state) {
    final snapshot = state.value;
    if (state.isLoading && snapshot == null) {
      return context.tr('Downloading master data…');
    }
    if (snapshot == null) return context.tr('Master data not synchronized');
    final synchronizedAt = snapshot.synchronizedAt as DateTime?;
    final source = snapshot.isFromCache as bool
        ? context.tr('Available offline')
        : context.tr('Up to date');
    if (synchronizedAt == null) return source;
    final local = synchronizedAt.toLocal();
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$source · ${context.tr('Last sync')}: $date';
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Chip(label: Text('$label: $count'));
}

class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Icon(icon)),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
