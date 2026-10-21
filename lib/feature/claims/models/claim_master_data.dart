import 'claim_service_item_model.dart';
import 'diagnosis_model.dart';

class ClaimAdministratorProfile {
  const ClaimAdministratorProfile({
    required this.code,
    required this.displayName,
    required this.healthFacilityCode,
    required this.healthFacilityName,
  });

  final String code;
  final String displayName;
  final String healthFacilityCode;
  final String healthFacilityName;
}

class ClaimMasterData {
  const ClaimMasterData({
    required this.administrator,
    required this.diagnoses,
    required this.services,
    required this.items,
  });

  final ClaimAdministratorProfile administrator;
  final List<Diagnosis> diagnoses;
  final List<MedicalService> services;
  final List<MedicationItem> items;
}

class ClaimMasterDataStore {
  ClaimMasterData? value;
}
