import 'claim_service_item_model.dart';
import 'diagnosis_model.dart';
import 'claim_program.dart';

class ClaimAdministratorProfile {
  const ClaimAdministratorProfile({
    this.id,
    required this.code,
    required this.displayName,
    required this.healthFacilityCode,
    required this.healthFacilityName,
    this.healthFacilityId,
  });

  final String? id;
  final String code;
  final String displayName;
  final String healthFacilityCode;
  final String healthFacilityName;
  final String? healthFacilityId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'displayName': displayName,
    'healthFacilityCode': healthFacilityCode,
    'healthFacilityName': healthFacilityName,
    'healthFacilityId': healthFacilityId,
  };

  factory ClaimAdministratorProfile.fromJson(Map<String, dynamic> json) =>
      ClaimAdministratorProfile(
        id: json['id']?.toString(),
        code: json['code']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        healthFacilityCode: json['healthFacilityCode']?.toString() ?? '',
        healthFacilityName: json['healthFacilityName']?.toString() ?? '',
        healthFacilityId: json['healthFacilityId']?.toString(),
      );
}

class ClaimMasterData {
  const ClaimMasterData({
    required this.administrator,
    required this.diagnoses,
    required this.services,
    required this.items,
    required this.programs,
  });

  final ClaimAdministratorProfile administrator;
  final List<Diagnosis> diagnoses;
  final List<MedicalService> services;
  final List<MedicationItem> items;
  final List<ClaimProgram> programs;

  Map<String, dynamic> toJson() => {
    'administrator': administrator.toJson(),
    'diagnoses': diagnoses.map((value) => value.toJson()).toList(),
    'services': services.map((value) => value.toJson()).toList(),
    'items': items.map((value) => value.toJson()).toList(),
    'programs': programs.map((value) => value.toJson()).toList(),
  };

  factory ClaimMasterData.fromJson(Map<String, dynamic> json) =>
      ClaimMasterData(
        administrator: ClaimAdministratorProfile.fromJson(
          Map<String, dynamic>.from(json['administrator'] as Map),
        ),
        diagnoses: _maps(json['diagnoses']).map(Diagnosis.fromJson).toList(),
        services: _maps(
          json['services'],
        ).map(MedicalService.fromJson).toList(),
        items: _maps(json['items']).map(MedicationItem.fromJson).toList(),
        programs: _maps(json['programs']).map(ClaimProgram.fromJson).toList(),
      );
}

class ClaimMasterDataStore {
  ClaimMasterData? value;
}

Iterable<Map<String, dynamic>> _maps(Object? value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is Map) yield Map<String, dynamic>.from(item);
  }
}
