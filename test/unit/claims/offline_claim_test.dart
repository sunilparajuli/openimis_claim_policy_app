import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_service_item_model.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_submission_model.dart';
import 'package:flutter_riverpod_template/feature/claims/models/diagnosis_model.dart';
import 'package:flutter_riverpod_template/feature/claims/repositories/claim_repository.dart';
import 'package:flutter_riverpod_template/feature/claims/repositories/offline_claim_repository.dart';
import 'package:flutter_riverpod_template/feature/shared/widgets/shimmer_loading.dart';

class MockRemoteClaimRepository implements ClaimRepository {
  bool submitSuccess = true;
  final List<ClaimSubmission> submittedClaims = [];

  @override
  Future<bool> submitClaim(ClaimSubmission claim) async {
    if (submitSuccess) {
      submittedClaims.add(claim);
      return true;
    }
    return false;
  }

  @override
  List<Diagnosis> getDiagnoses() => [];

  @override
  List<MedicalService> getAvailableServices() => [];

  @override
  List<MedicationItem> getAvailableItems() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ClaimSubmission createSampleSubmission(String code) {
    return ClaimSubmission(
      claimCode: code,
      healthFacility: 'St. Mary Referral Hospital',
      claimAdmin: 'Dr. John Doe',
      insureeChfId: 'CHF-9823412',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 2),
      claimDate: DateTime(2026, 1, 2),
      visitType: ClaimVisitType.emergency,
      primaryDiagnosis: const Diagnosis(code: 'A09', name: 'Gastroenteritis'),
      services: [
        ClaimedService(
          service: const MedicalService(code: 'SRV001', name: 'General Consultation', price: 20.0),
          quantity: 1,
        ),
      ],
      items: [
        ClaimedItem(
          item: const MedicationItem(code: 'MED001', name: 'Amoxicillin', price: 5.0),
          quantity: 2,
        ),
      ],
    );
  }

  group('OfflineClaimRepository & SQLite schema', () {
    test('saveClaim saves offline claim and increments pending count', () async {
      final repo = OfflineClaimRepository();
      final initialCount = await repo.countPendingClaims();

      final claim1 = createSampleSubmission('CLM-TEST-001');
      await repo.saveClaim(claim1, isPending: true);

      final countAfter = await repo.countPendingClaims();
      expect(countAfter, equals(initialCount + 1));

      final pending = await repo.getPendingClaims();
      final savedRecord = pending.firstWhere((r) => r.claimCode == 'CLM-TEST-001');
      expect(savedRecord.insureeChfId, equals('CHF-9823412'));
      expect(savedRecord.totalAmount, equals(30.0)); // 20 + 2*5 = 30
      expect(savedRecord.uploadStatus, equals('pending'));
    });

    test('syncAllPendingClaims uploads pending claims and marks them uploaded', () async {
      final repo = OfflineClaimRepository();
      final mockRemote = MockRemoteClaimRepository();

      final claim2 = createSampleSubmission('CLM-SYNC-002');
      await repo.saveClaim(claim2, isPending: true);

      final result = await repo.syncAllPendingClaims(mockRemote);
      expect(result.syncedCount, greaterThanOrEqualTo(1));
      expect(result.failedCount, equals(0));

      final remaining = await repo.getPendingClaims();
      final syncedRecord = remaining.where((r) => r.claimCode == 'CLM-SYNC-002');
      expect(syncedRecord.isEmpty, isTrue);
    });

    test('PendingClaimsCountNotifier tracks and updates state via ProviderContainer', () async {
      final container = ProviderContainer();
      final claim = createSampleSubmission('CLM-NOTIF-003');
      await container.read(pendingClaimsCountProvider.notifier).saveOffline(claim);
      expect(container.read(pendingClaimsCountProvider), greaterThan(0));

      final mockRemote = MockRemoteClaimRepository();
      await container.read(pendingClaimsCountProvider.notifier).syncAll(mockRemote);
      expect(container.read(pendingClaimsCountProvider), equals(0));
    });
  });

  group('Shimmer Loading Widgets', () {
    testWidgets('Shimmer and ShimmerBox render properly without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Shimmer(
              child: ShimmerBox(width: 100, height: 20),
            ),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('InsureeVerificationShimmer renders skeleton structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InsureeVerificationShimmer(),
          ),
        ),
      );

      expect(find.byType(InsureeVerificationShimmer), findsOneWidget);
      expect(find.byType(ShimmerCircle), findsOneWidget);
    });

    testWidgets('ClaimListShimmer renders list placeholders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClaimListShimmer(count: 3),
          ),
        ),
      );

      expect(find.byType(ClaimListShimmer), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(3));
    });
  });
}
