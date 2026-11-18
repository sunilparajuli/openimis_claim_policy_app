import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_program.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_service_item_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/diagnosis_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/services/claim_xml_archive_exporter.dart';

void main() {
  final claim = ClaimSubmission(
    claimCode: 'CLM&001',
    healthFacility: 'HF1',
    claimAdmin: 'ADMIN1',
    insureeChfId: '120902348063480',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 2),
    claimDate: DateTime(2026, 1, 3),
    visitType: ClaimVisitType.other,
    guaranteeNo: 'CC240524',
    program: const ClaimProgram(id: '2', code: 'CCS', name: 'Chèque Santé'),
    primaryDiagnosis: const Diagnosis(id: '10', code: 'A09', name: 'Diagnosis'),
    items: [
      ClaimedItem(
        item: const MedicationItem(
          id: '20',
          code: 'I1',
          name: 'Item',
          price: 5,
        ),
        quantity: 2,
      ),
    ],
    services: [
      ClaimedService(
        service: const MedicalService(
          id: '30',
          code: 'S1',
          name: 'Service',
          price: 10,
          category: 'F',
        ),
      ),
    ],
  );

  test('exports one legacy-compatible XML file in an AES protected ZIP', () {
    const exporter = ClaimXmlArchiveExporter(password: 'build-secret');
    final bytes = exporter.export([claim]);

    expect(
      () => ZipDecoder()
          .decodeBytes(bytes, password: 'wrong', verify: true)
          .files
          .single
          .content,
      throwsA(isA<ArchivePasswordException>()),
    );
    final archive = ZipDecoder().decodeBytes(
      bytes,
      password: 'build-secret',
      verify: true,
    );
    expect(archive.files, hasLength(1));
    expect(archive.files.single.name, startsWith('Claim_HF1_CLM_001_'));
    final xml = utf8.decode(archive.files.single.content as List<int>);
    expect(xml, contains('<Claim><Details>'));
    expect(xml, contains('<Program>CCS</Program>'));
    expect(xml, contains('<GuaranteeNumber>CC240524</GuaranteeNumber>'));
    expect(xml, contains('<CHFID>120902348063480</CHFID>'));
    expect(xml, contains('<ClaimCode>CLM&amp;001</ClaimCode>'));
    expect(xml, contains('<ItemCode>I1</ItemCode>'));
    expect(xml, contains('<ServiceCode>S1</ServiceCode>'));
  });

  test('never creates an unprotected archive without build password', () {
    const exporter = ClaimXmlArchiveExporter(password: '');
    expect(() => exporter.export([claim]), throwsStateError);
  });
}
