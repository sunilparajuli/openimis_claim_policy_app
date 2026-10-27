import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_service_item_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/diagnosis_model.dart';

void main() {
  test('claim payload matches the openIMIS Java FHIR contract', () {
    final claim = ClaimSubmission(
      claimCode: 'CLM-1',
      healthFacility: 'HF1',
      claimAdmin: 'CA1',
      insureeChfId: '070707070',
      startDate: DateTime(2026, 10, 22),
      endDate: DateTime(2026, 10, 23),
      claimDate: DateTime(2026, 10, 23),
      visitType: ClaimVisitType.other,
      guaranteeNo: 'G1',
      primaryDiagnosis: const Diagnosis(code: 'A09', name: 'Diagnosis'),
      items: [
        ClaimedItem(
          item: const MedicationItem(code: 'MED1', name: 'Medicine', price: 4),
          quantity: 2,
        ),
      ],
      services: [
        ClaimedService(
          service: const MedicalService(
            code: 'SRV1',
            name: 'Service',
            price: 5,
          ),
        ),
      ],
    );

    final json = claim.toFhirJson();

    expect(json['status'], 'active');
    expect(json['use'], 'claim');
    expect(json['provider']['identifier']['value'], 'HF1');
    expect(json['enterer']['identifier']['value'], 'CA1');
    expect(json['patient']['identifier']['value'], '070707070');
    expect(json['priority']['coding'][0]['code'], 'normal');
    expect(json['total'], {'currency': r'$', 'value': 13.0});

    final items = json['item'] as List<dynamic>;
    expect(items[0]['category']['text'], 'item');
    expect(items[0]['extension'][0]['url'], 'Medication');
    expect(items[0]['productOrService']['text'], 'MED1');
    expect(items[1]['category']['text'], 'service');
    expect(items[1]['extension'][0]['url'], 'ActivityDefinition');
    expect(items[1]['productOrService']['text'], 'SRV1');
    expect(json['insurance'][0]['coverage']['identifier']['value'], 'G1');
  });
}
