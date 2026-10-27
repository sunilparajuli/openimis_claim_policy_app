import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/core/config/claim_form_requirements_provider.dart';

void main() {
  test('claim form requirements default to optional frontend fields', () {
    const requirements = ClaimFormRequirements();

    expect(requirements.guaranteeNumber, isFalse);
    expect(requirements.secondaryDiagnosis, isFalse);
    expect(requirements.medicalService, isFalse);
    expect(requirements.medicalItem, isFalse);
  });

  test('claim form requirements serialize and restore', () {
    final configured = const ClaimFormRequirements().copyWith(
      guaranteeNumber: true,
      medicalService: true,
    );

    final restored = ClaimFormRequirements.fromJson(configured.toJson());

    expect(restored.guaranteeNumber, isTrue);
    expect(restored.medicalService, isTrue);
    expect(restored.secondaryDiagnosis, isFalse);
    expect(restored.medicalItem, isFalse);
  });
}
