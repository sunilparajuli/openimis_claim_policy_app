import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';

class OfflinePolicyEnrollment {
  const OfflinePolicyEnrollment({
    required this.id,
    required this.family,
    required this.members,
    required this.policies,
    required this.createdAt,
  });

  final String id;
  final PolicyFamilyDraft family;
  final List<PolicyInsureeDraft> members;
  final List<PolicyDraft> policies;
  final DateTime createdAt;

  OfflinePolicyEnrollment withMember(PolicyInsureeDraft member) {
    final normalized = member.validatedChfId(family.application);
    if (family.head.validatedChfId(family.application) == normalized ||
        members.any(
          (current) => current.validatedChfId(family.application) == normalized,
        )) {
      throw const FormatException(
        'This MPI already belongs to the pending family.',
      );
    }
    return OfflinePolicyEnrollment(
      id: id,
      family: family,
      members: List.unmodifiable([...members, member]),
      policies: policies,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family': family.toJson(),
    'members': members.map((member) => member.toJson()).toList(),
    'policies': policies.map((policy) => policy.toJson()).toList(),
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory OfflinePolicyEnrollment.fromJson(Map<String, dynamic> json) =>
      OfflinePolicyEnrollment(
        id: json['id'].toString(),
        family: PolicyFamilyDraft.fromJson(
          Map<String, dynamic>.from(json['family'] as Map),
        ),
        members: (json['members'] as List? ?? const [])
            .map(
              (item) => PolicyInsureeDraft.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
        policies: (json['policies'] as List? ?? const [])
            .map(
              (item) =>
                  PolicyDraft.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(growable: false),
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );
}
