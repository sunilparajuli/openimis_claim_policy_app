import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/policies/data/offline/policy_enrollment_database.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/offline_insuree_update.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/offline_policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/policies/repositories/policy_enrollment_repository.dart';

final offlinePolicyEnrollmentRepositoryProvider =
    Provider<OfflinePolicyEnrollmentRepository>(
      (ref) => OfflinePolicyEnrollmentRepository(
        PolicyEnrollmentDatabase.instance,
        ref.watch(policyEnrollmentRepositoryProvider),
      ),
    );

class PolicyEnrollmentSyncResult {
  const PolicyEnrollmentSyncResult({
    required this.synced,
    required this.failed,
  });

  final int synced;
  final int failed;
}

class OfflinePolicyEnrollmentRepository {
  const OfflinePolicyEnrollmentRepository(this._database, this._remote);

  final PolicyEnrollmentDatabase _database;
  final PolicyEnrollmentRepository _remote;

  Future<void> save(OfflinePolicyEnrollment enrollment) =>
      _database.save(enrollment);

  Future<List<PolicyEnrollmentRecord>> pending() => _database.pending();

  Future<bool> isChequeQueued(String chequeNumber) async {
    final value = chequeNumber.trim();
    if (value.isEmpty) return false;
    return (await pending()).any(
      (record) => record.enrollment.policies.any(
        (policy) => policy.policyNumber == value,
      ),
    );
  }

  Future<OfflinePolicyEnrollment> addMember(
    String enrollmentId,
    PolicyInsureeDraft member,
  ) => _database.addMember(enrollmentId, member);

  Future<void> saveInsureeUpdate(OfflineInsureeUpdate update) =>
      _database.saveInsureeUpdate(update);

  Future<List<InsureeUpdateRecord>> pendingInsureeUpdates() =>
      _database.pendingInsureeUpdates();

  Future<PolicyEnrollmentSyncResult> synchronize() async {
    var synced = 0;
    var failed = 0;
    for (final record in await pending()) {
      final enrollment = record.enrollment;
      try {
        final headChfId = enrollment.family.head.validatedChfId(
          enrollment.family.application,
        );
        final familyMutationId = '${enrollment.id}-family';
        FamilyServerReference family;
        try {
          family = await _remote.familyForHead(headChfId);
          final priorCreation = await _remote.mutationStatus(familyMutationId);
          if (priorCreation?.succeeded != true) {
            throw StateError(
              'An existing MPI cannot be used again as family head.',
            );
          }
        } on FormatException {
          await _remote.createFamily(
            enrollment.family,
            clientMutationId: familyMutationId,
          );
          await _remote.waitForMutation(familyMutationId);
          family = await _remote.familyForHead(headChfId);
        }

        for (var index = 0; index < enrollment.members.length; index++) {
          final member = enrollment.members[index];
          final memberChfId = member.validatedChfId(
            enrollment.family.application,
          );
          if (await _remote.insureeExists(memberChfId)) continue;
          final mutationId = '${enrollment.id}-member-$index';
          await _remote.createInsuree(
            member,
            application: enrollment.family.application,
            familyId: family.id,
            clientMutationId: mutationId,
          );
          await _remote.waitForMutation(mutationId);
        }

        for (var index = 0; index < enrollment.policies.length; index++) {
          final policy = enrollment.policies[index];
          if (await _remote.policyExistsForFamily(
            family.uuid,
            policy.productCode ?? '',
          )) {
            continue;
          }
          final mutationId = '${enrollment.id}-policy-$index';
          await _remote.createPolicy(
            policy.withFamilyId(family.id),
            clientMutationId: mutationId,
          );
          await _remote.waitForMutation(mutationId);
        }
        await _database.markSynced(enrollment.id);
        synced++;
      } catch (error) {
        await _database.markFailed(enrollment.id, error);
        failed++;
      }
    }
    for (final record in await pendingInsureeUpdates()) {
      final update = record.update;
      try {
        await _remote.updateInsuree(
          update.insuree,
          application: update.application,
          clientMutationId: update.id,
        );
        await _remote.waitForMutation(update.id);
        await _database.markInsureeUpdateSynced(update.id);
        synced++;
      } catch (error) {
        await _database.markInsureeUpdateFailed(update.id, error);
        failed++;
      }
    }
    return PolicyEnrollmentSyncResult(synced: synced, failed: failed);
  }
}
