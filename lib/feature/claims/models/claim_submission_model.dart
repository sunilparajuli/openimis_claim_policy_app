import 'package:flutter_riverpod_template/feature/claims/models/claim_service_item_model.dart';
import 'package:flutter_riverpod_template/feature/claims/models/diagnosis_model.dart';

enum ClaimVisitType {
  emergency('E', 'Emergency'),
  referral('R', 'Referral'),
  other('O', 'Other');

  final String code;
  final String label;
  const ClaimVisitType(this.code, this.label);
}

class ClaimSubmission {
  final String claimCode;
  final String healthFacility;
  final String claimAdmin;
  final String insureeChfId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime claimDate;
  final ClaimVisitType visitType;
  final String? guaranteeNo;
  final Diagnosis primaryDiagnosis;
  final List<Diagnosis> secondaryDiagnoses;
  final List<ClaimedService> services;
  final List<ClaimedItem> items;

  ClaimSubmission({
    required this.claimCode,
    required this.healthFacility,
    required this.claimAdmin,
    required this.insureeChfId,
    required this.startDate,
    required this.endDate,
    required this.claimDate,
    required this.visitType,
    this.guaranteeNo,
    required this.primaryDiagnosis,
    this.secondaryDiagnoses = const [],
    this.services = const [],
    this.items = const [],
  });

  double get servicesTotal =>
      services.fold(0.0, (sum, item) => sum + item.total);

  double get itemsTotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get grandTotal => servicesTotal + itemsTotal;

  String get healthFacilityName => healthFacility;
  String get claimAdministrator => claimAdmin;
  double get totalAmount => grandTotal;

  Map<String, dynamic> toJson() => {
    'claimCode': claimCode,
    'healthFacility': healthFacility,
    'claimAdmin': claimAdmin,
    'insureeChfId': insureeChfId,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'claimDate': claimDate.toIso8601String(),
    'visitType': visitType.name,
    'guaranteeNo': guaranteeNo,
    'primaryDiagnosis': primaryDiagnosis.toJson(),
    'secondaryDiagnoses': secondaryDiagnoses.map((d) => d.toJson()).toList(),
    'services': services.map((s) => s.toJson()).toList(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory ClaimSubmission.fromJson(Map<String, dynamic> json) {
    return ClaimSubmission(
      claimCode: json['claimCode'] as String? ?? '',
      healthFacility: json['healthFacility'] as String? ?? '',
      claimAdmin: json['claimAdmin'] as String? ?? '',
      insureeChfId: json['insureeChfId'] as String? ?? '',
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      claimDate:
          DateTime.tryParse(json['claimDate'] as String? ?? '') ??
          DateTime.now(),
      visitType: ClaimVisitType.values.firstWhere(
        (v) => v.name == json['visitType'],
        orElse: () => ClaimVisitType.emergency,
      ),
      guaranteeNo: json['guaranteeNo'] as String?,
      primaryDiagnosis: Diagnosis.fromJson(
        json['primaryDiagnosis'] as Map<String, dynamic>? ?? {},
      ),
      secondaryDiagnoses: ((json['secondaryDiagnoses'] as List?) ?? [])
          .map((d) => Diagnosis.fromJson(d as Map<String, dynamic>))
          .toList(),
      services: ((json['services'] as List?) ?? [])
          .map((s) => ClaimedService.fromJson(s as Map<String, dynamic>))
          .toList(),
      items: ((json['items'] as List?) ?? [])
          .map((i) => ClaimedItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Formats the submission according to openIMIS FHIR R4 Claim specifications
  Map<String, dynamic> toFhirJson() {
    return {
      'resourceType': 'Claim',
      'identifier': [
        {
          'type': {
            'coding': [
              {
                'system':
                    'https://openimis.github.io/openimis_fhir_r4_ig/CodeSystem/openimis-identifiers',
                'code': 'Code',
              },
            ],
          },
          'value': claimCode,
        },
      ],
      'billablePeriod': {
        'start': startDate.toIso8601String().substring(0, 10),
        'end': endDate.toIso8601String().substring(0, 10),
      },
      'created': claimDate.toIso8601String().substring(0, 10),
      'type': {
        'coding': [
          {
            'system':
                'https://openimis.github.io/openimis_fhir_r4_ig/CodeSystem-claim-visit-type.html',
            'code': visitType.code,
            'display': visitType.label,
          },
        ],
      },
      'patient': {
        'identifier': {'value': insureeChfId},
      },
      'diagnosis': [
        {
          'sequence': 1,
          'diagnosisCodeableConcept': {
            'coding': [
              {
                'system': 'http://hl7.org/fhir/sid/icd-10',
                'code': primaryDiagnosis.code,
                'display': primaryDiagnosis.name,
              },
            ],
          },
        },
        ...secondaryDiagnoses.asMap().entries.map(
          (entry) => {
            'sequence': entry.key + 2,
            'diagnosisCodeableConcept': {
              'coding': [
                {
                  'system': 'http://hl7.org/fhir/sid/icd-10',
                  'code': entry.value.code,
                  'display': entry.value.name,
                },
              ],
            },
          },
        ),
      ],
      'item': [
        ...services.asMap().entries.map(
          (entry) => {
            'sequence': entry.key + 1,
            'category': {'text': 'Service'},
            'productOrService': {
              'coding': [
                {
                  'code': entry.value.service.code,
                  'display': entry.value.service.name,
                },
              ],
            },
            'quantity': {'value': entry.value.quantity},
            'unitPrice': {'value': entry.value.price},
            'net': {'value': entry.value.total},
          },
        ),
        ...items.asMap().entries.map(
          (entry) => {
            'sequence': services.length + entry.key + 1,
            'category': {'text': 'Item'},
            'productOrService': {
              'coding': [
                {
                  'code': entry.value.item.code,
                  'display': entry.value.item.name,
                },
              ],
            },
            'quantity': {'value': entry.value.quantity},
            'unitPrice': {'value': entry.value.price},
            'net': {'value': entry.value.total},
          },
        ),
      ],
      'total': {'value': grandTotal},
    };
  }
}
