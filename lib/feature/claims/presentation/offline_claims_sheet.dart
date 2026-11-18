import 'dart:io';

import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/config/currency_provider.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/claims/data/offline/claim_sqlite_database.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_repository.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/offline_claim_repository.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';
import 'package:openimis_claim_policy_app/feature/claims/services/claim_xml_archive_exporter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final Set<String> _selectedClaimUuids = {};

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
        _selectedClaimUuids.removeWhere(
          (uuid) => !list.any((record) => record.claimUuid == uuid),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _syncSelected() async {
    final selected = _records
        .where((record) => _selectedClaimUuids.contains(record.claimUuid))
        .toList(growable: false);
    if (selected.isEmpty) return;
    setState(() => _isSyncing = true);
    final remoteRepo = ref.read(claimRepositoryProvider);
    final notifier = ref.read(pendingClaimsCountProvider.notifier);

    final result = await notifier.syncSelected(selected, remoteRepo);
    await _loadPendingClaims();

    if (mounted) {
      setState(() => _isSyncing = false);
      final allSucceeded = result.failedCount == 0;
      showAppFeedbackDialog(
        context: context,
        type: allSucceeded ? AppFeedbackType.success : AppFeedbackType.warning,
        message: allSucceeded
            ? 'Upload complete: ${result.syncedCount} selected claim(s) uploaded.'
            : 'Upload completed with errors: ${result.syncedCount} uploaded, ${result.failedCount} failed.',
      );
    }
  }

  Future<void> _exportSelected() async {
    final selected = _records
        .where((record) => _selectedClaimUuids.contains(record.claimUuid))
        .toList(growable: false);
    final submissions = selected
        .map((record) => record.submission)
        .whereType<ClaimSubmission>()
        .toList(growable: false);
    if (submissions.length != selected.length) {
      showAppFeedbackDialog(
        context: context,
        type: AppFeedbackType.warning,
        message: context.tr('One or more selected claim payloads are missing.'),
      );
      return;
    }
    setState(() => _isSyncing = true);
    try {
      final bytes = const ClaimXmlArchiveExporter().export(submissions);
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final file = File('${directory.path}/Claims_$timestamp.zip');
      await file.writeAsBytes(bytes, flush: true);
      await ref
          .read(offlineClaimRepositoryProvider)
          .markClaimsExported(selected);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: context.tr('Export claims'),
          subject: context.tr('Protected openIMIS claim archive'),
          files: [XFile(file.path, mimeType: 'application/zip')],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      await _loadPendingClaims();
    } catch (error) {
      if (!mounted) return;
      showAppFeedbackDialog(
        context: context,
        type: AppFeedbackType.error,
        message: error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('FormatException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _toggleSelectAll(bool selected) {
    setState(() {
      _selectedClaimUuids
        ..clear()
        ..addAll(selected ? _records.map((record) => record.claimUuid) : []);
    });
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
                      context.tr('Pending Claims'),
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
                              context.tr('No claim found.'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr(
                                'There are no pending claims to upload.',
                              ),
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
                : Column(
                    children: [
                      CheckboxListTile(
                        key: const Key('select_all_claims'),
                        value:
                            _records.isNotEmpty &&
                            _selectedClaimUuids.length == _records.length,
                        tristate: _selectedClaimUuids.isNotEmpty,
                        onChanged: _isSyncing
                            ? null
                            : (value) => _toggleSelectAll(value == true),
                        title: Text(context.tr('Select all')),
                        subtitle: Text(
                          '${_selectedClaimUuids.length} of ${_records.length} selected',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
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
                              child: CheckboxListTile(
                                key: Key('claim_selection_${rec.claimUuid}'),
                                value: _selectedClaimUuids.contains(
                                  rec.claimUuid,
                                ),
                                onChanged: _isSyncing
                                    ? null
                                    : (selected) => setState(() {
                                        if (selected == true) {
                                          _selectedClaimUuids.add(
                                            rec.claimUuid,
                                          );
                                        } else {
                                          _selectedClaimUuids.remove(
                                            rec.claimUuid,
                                          );
                                        }
                                      }),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.all(16),
                                title: Column(
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
                                            color:
                                                CustomColors
                                                    .ExpiryOrange.withValues(
                                                  alpha: 0.15,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                        Expanded(
                                          child: Text(
                                            'Insurance No: ${rec.insureeChfId}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
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
                                    if (rec.uploadMessage?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        rec.uploadMessage!
                                            .replaceFirst(
                                              'FormatException: ',
                                              '',
                                            )
                                            .replaceFirst('Bad state: ', ''),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
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
                    ],
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
                      variant: AppButtonVariant.secondary,
                      onPressed: _isSyncing || _selectedClaimUuids.isEmpty
                          ? null
                          : _exportSelected,
                      icon: const Icon(Icons.archive_outlined),
                      label: Text(context.tr('Export XML')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      variant: AppButtonVariant.primary,
                      onPressed: _isSyncing || _selectedClaimUuids.isEmpty
                          ? null
                          : _syncSelected,
                      isLoading: _isSyncing,
                      icon: const Icon(Icons.sync),
                      label: Text(
                        _isSyncing
                            ? 'Uploading…'
                            : 'Upload Selected (${_selectedClaimUuids.length})',
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
