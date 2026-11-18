import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/claims/data/local/claim_master_data_cache.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_master_data.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_program.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_service_item_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/diagnosis_model.dart';

void main() {
  late Directory directory;
  late ClaimMasterDataCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('claim-master-cache-');
    cache = ClaimMasterDataCache(directory: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('persists and restores the complete claim catalogue', () async {
    final source = ClaimMasterData(
      administrator: const ClaimAdministratorProfile(
        id: 'ca-1',
        code: 'RHOS0011',
        displayName: 'Claim Administrator',
        healthFacilityCode: 'HF1',
        healthFacilityName: 'Facility',
        healthFacilityId: 'hf-1',
      ),
      diagnoses: const [Diagnosis(id: 'd-1', code: 'A00', name: 'Cholera')],
      services: List.generate(
        30000,
        (index) => MedicalService(
          id: 's-$index',
          code: 'S$index',
          name: 'Service $index',
          price: index.toDouble(),
          programCode: index.isEven ? 'CSU' : 'CCS',
        ),
      ),
      items: List.generate(
        30000,
        (index) => MedicationItem(
          id: 'i-$index',
          code: 'I$index',
          name: 'Item $index',
          price: index / 10,
          programCode: index.isEven ? 'CSU' : 'VIH',
        ),
      ),
      programs: const [ClaimProgram(id: 'p-1', code: 'CSU', name: 'CSU')],
    );

    await cache.save(source);
    final restored = await cache.load('rhos0011');

    expect(restored, isNotNull);
    expect(restored!.services, hasLength(30000));
    expect(restored.items, hasLength(30000));
    expect(restored.services[1].programCode, 'CCS');
    expect(restored.items[1].programCode, 'VIH');
    expect(restored.diagnoses.single.code, 'A00');
    expect(restored.programs.single.code, 'CSU');
    expect(await cache.load('ANOTHER-ADMIN'), isNull);
  });
}
