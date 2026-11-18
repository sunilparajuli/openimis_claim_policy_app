import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';

class OfflineInsureeUpdate {
  const OfflineInsureeUpdate({
    required this.id,
    required this.application,
    required this.insuree,
    required this.createdAt,
  });

  final String id;
  final PolicyApplication application;
  final PolicyInsureeDraft insuree;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'application': application.name,
    'insuree': insuree.toJson(),
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory OfflineInsureeUpdate.fromJson(Map<String, dynamic> json) =>
      OfflineInsureeUpdate(
        id: json['id'].toString(),
        application: PolicyApplication.values.firstWhere(
          (value) => value.name == json['application'],
          orElse: () => PolicyApplication.csu,
        ),
        insuree: PolicyInsureeDraft.fromJson(
          Map<String, dynamic>.from(json['insuree'] as Map),
        ),
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );
}
