import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/claims/data/offline/claim_sqlite_database.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_repository.dart';

class OfflineClaimRepository {
  final ClaimSqliteDatabase _db = ClaimSqliteDatabase.instance;

  Future<void> saveClaim(
    ClaimSubmission submission, {
    bool isPending = true,
  }) async {
    await _db.saveClaimOffline(submission);
  }

  Future<List<OfflineClaimRecord>> getPendingClaims() async {
    return _db.getPendingClaims();
  }

  Future<int> countPendingClaims() async {
    return _db.countPendingClaims();
  }

  /// Sync all pending offline claims with openIMIS FHIR R4 server
  Future<SyncResult> syncAllPendingClaims(ClaimRepository remoteRepo) async {
    final pending = await getPendingClaims();
    if (pending.isEmpty) {
      return const SyncResult(syncedCount: 0, failedCount: 0, total: 0);
    }

    int synced = 0;
    int failed = 0;

    for (final record in pending) {
      try {
        if (record.submission != null) {
          final success = await remoteRepo.submitClaim(record.submission!);
          if (success) {
            await _db.markClaimUploaded(record.claimUuid);
            synced++;
          } else {
            await _db.markClaimUploadFailed(
              record.claimUuid,
              'Server did not accept the claim',
            );
            failed++;
          }
        } else {
          await _db.markClaimUploadFailed(
            record.claimUuid,
            'Offline claim payload is unavailable',
          );
          failed++;
        }
      } catch (error) {
        await _db.markClaimUploadFailed(record.claimUuid, error);
        failed++;
      }
    }

    return SyncResult(
      syncedCount: synced,
      failedCount: failed,
      total: pending.length,
    );
  }
}

class SyncResult {
  final int syncedCount;
  final int failedCount;
  final int total;

  const SyncResult({
    required this.syncedCount,
    required this.failedCount,
    required this.total,
  });
}

final offlineClaimRepositoryProvider = Provider<OfflineClaimRepository>((ref) {
  return OfflineClaimRepository();
});

/// Riverpod Notifier for the count of pending offline claims
class PendingClaimsCountNotifier extends Notifier<int> {
  OfflineClaimRepository get _repo => ref.read(offlineClaimRepositoryProvider);

  @override
  int build() {
    refresh();
    return 0;
  }

  Future<void> refresh() async {
    state = await _repo.countPendingClaims();
  }

  Future<void> saveOffline(ClaimSubmission submission) async {
    await _repo.saveClaim(submission, isPending: true);
    await refresh();
  }

  Future<SyncResult> syncAll(ClaimRepository remoteRepo) async {
    final result = await _repo.syncAllPendingClaims(remoteRepo);
    await refresh();
    return result;
  }
}

final pendingClaimsCountProvider =
    NotifierProvider<PendingClaimsCountNotifier, int>(
      PendingClaimsCountNotifier.new,
    );
