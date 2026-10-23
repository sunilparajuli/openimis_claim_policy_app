import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/config/currency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/claims/data/offline/claim_sqlite_database.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_repository.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/offline_claim_repository.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';

class OfflineClaimsSheet extends ConsumerStatefulWidget {
  const OfflineClaimsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAppBottomSheet(
      context: context,
      builder: (_) => const OfflineClaimsSheet(),
    );
  }

  @override
  ConsumerState<OfflineClaimsSheet> createState() => _OfflineClaimsSheetState();
}

class _OfflineClaimsSheetState extends ConsumerState<OfflineClaimsSheet> {
  bool _isLoading = true;
  bool _isSyncing = false;
  List<OfflineClaimRecord> _records = [];

  MoneyFormatter get _money => ref.read(moneyFormatterProvider);

  @override
  void initState() {
    super.initState();
    _loadPendingClaims();
  }

  Future<void> _loadPendingClaims() async {
    setState(() => _isLoading = true);
    final repo = ref.read(offlineClaimRepositoryProvider);
    final list = await repo.getPendingClaims();
    if (mounted) {
      setState(() {
        _records = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _syncAll() async {
    setState(() => _isSyncing = true);
    final remoteRepo = ref.read(claimRepositoryProvider);
    final notifier = ref.read(pendingClaimsCountProvider.notifier);

    final result = await notifier.syncAll(remoteRepo);
    await _loadPendingClaims();

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CustomColors.SuccessGreen,
          content: Text(
            'Sync Complete: ${result.syncedCount} claims uploaded to FHIR server.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(moneyFormatterProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Claims',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_records.length} claim(s) ready to upload',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ClaimListShimmer(count: 4),
                  )
                : _records.isEmpty
                ? SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: CustomColors.BrandPurple.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_done_outlined,
                                size: 48,
                                color: CustomColors.BrandPurple,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No claim found.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'There are no pending claims to upload.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final rec = _records[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rec.claimCode,
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
                                      color: CustomColors
                                          .ExpiryOrange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      rec.uploadStatus,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: CustomColors.ExpiryOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Insurance No: ${rec.insureeChfId}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _money.format(rec.totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: CustomColors.BrandPurple,
                                    ),
                                  ),
                                ],
                              ),
                              if (rec.submission != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Dx: ${rec.submission!.primaryDiagnosis.code} - ${rec.submission!.primaryDiagnosis.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_records.isNotEmpty) ...[
                  Expanded(
                    child: AppButton(
                      variant: AppButtonVariant.primary,
                      onPressed: _isSyncing ? null : _syncAll,
                      isLoading: _isSyncing,
                      icon: const Icon(Icons.sync),
                      label: Text(
                        _isSyncing
                            ? 'Uploading…'
                            : 'Upload Claims (${_records.length})',
                      ),
                      style: AppButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: CustomColors.BrandPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
