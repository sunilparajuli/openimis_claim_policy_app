import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/offline_policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';

void main() {
  test('offline CSU/HIV enrolment payload survives JSON persistence', () {
    final original = OfflinePolicyEnrollment(
      id: 'enrollment-1',
      family: PolicyFamilyDraft(
        application: PolicyApplication.hiv,
        locationId: 8,
        head: PolicyInsureeDraft(
          chfId: 'TARV-001',
          lastName: 'Doe',
          otherNames: 'Jane',
          genderId: 'F',
          dateOfBirth: DateTime(1992, 3, 4),
          isHead: true,
        ),
      ),
      members: [
        PolicyInsureeDraft(
          chfId: 'TARV-002',
          lastName: 'Doe',
          otherNames: 'John',
          genderId: 'M',
          dateOfBirth: DateTime(2012, 5, 6),
          relationshipId: 2,
        ),
      ],
      policies: [
        PolicyDraft(
          familyId: 0,
          enrolmentDate: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 12, 31),
          value: 1000,
          productId: 5,
          officerId: 6,
          productCode: 'VIH1',
        ),
      ],
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final restored = OfflinePolicyEnrollment.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(original.toJson())) as Map,
      ),
    );
    expect(restored.family.application, PolicyApplication.hiv);
    expect(restored.family.head.chfId, 'TARV-001');
    expect(restored.members.single.relationshipId, 2);
    expect(restored.policies.single.productId, 5);
    expect(restored.policies.single.productCode, 'VIH1');
    expect(restored.policies.single.withFamilyId(42).familyId, 42);
  });

  test('persisted family member addition rejects duplicate MPI values', () {
    final enrollment = OfflinePolicyEnrollment(
      id: 'enrollment-2',
      family: PolicyFamilyDraft(
        application: PolicyApplication.csu,
        locationId: 8,
        head: PolicyInsureeDraft(
          chfId: '120902348063480',
          lastName: 'Doe',
          otherNames: 'Jane',
          genderId: 'F',
          dateOfBirth: DateTime(1992, 3, 4),
          isHead: true,
        ),
      ),
      members: const [],
      policies: const [],
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final member = PolicyInsureeDraft(
      chfId: '120902348063481',
      lastName: 'Doe',
      otherNames: 'John',
      genderId: 'M',
      dateOfBirth: DateTime(2012, 5, 6),
      relationshipId: 2,
    );

    final updated = enrollment.withMember(member);
    expect(updated.members.single.relationshipId, 2);
    expect(() => updated.withMember(member), throwsFormatException);
    expect(
      () => enrollment.withMember(
        PolicyInsureeDraft(
          chfId: ' 120902348063480 ',
          lastName: 'Doe',
          otherNames: 'Duplicate',
          genderId: 'F',
          dateOfBirth: DateTime(2010),
        ),
      ),
      throwsFormatException,
    );
  });
}
