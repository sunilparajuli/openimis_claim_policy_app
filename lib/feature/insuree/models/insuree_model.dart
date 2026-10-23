class Insuree {
  final String chfId;
  final String fullName;
  final String? gender;
  final String? dob;
  final String? photoUrl;
  final String? healthFacilityName;
  final List<InsureePolicy> policies;

  const Insuree({
    required this.chfId,
    required this.fullName,
    this.gender,
    this.dob,
    this.photoUrl,
    this.healthFacilityName,
    this.policies = const [],
  });

  InsureePolicy? get activePolicy {
    for (final p in policies) {
      if (p.status.toLowerCase() == 'active' ||
          p.status.toLowerCase() == 'ready') {
        return p;
      }
    }
    return policies.isNotEmpty ? policies.first : null;
  }

  factory Insuree.fromJson(Map<String, dynamic> json) {
    return Insuree(
      chfId:
          json['chfId']?.toString() ?? json['insureeCHFID']?.toString() ?? '',
      fullName:
          json['fullName']?.toString() ??
          json['name']?.toString() ??
          'Unknown Insuree',
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString() ?? json['birthDate']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['photo']?.toString(),
      healthFacilityName: json['healthFacility']?['name']?.toString(),
      policies:
          (json['policies'] as List<dynamic>?)
              ?.map((p) => InsureePolicy.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'chfId': chfId,
    'fullName': fullName,
    'gender': gender,
    'dob': dob,
    'photoUrl': photoUrl,
    'healthFacilityName': healthFacilityName,
    'policies': policies.map((p) => p.toJson()).toList(),
  };
}

class InsureePolicy {
  final String code;
  final String name;
  final String status; // ACTIVE, SUSPENDED, EXPIRED, IDLE
  final String? expiryDate;
  final double? ceilingOp;
  final double? ceilingIp;
  final double? deductibleOp;
  final double? deductibleIp;
  final int? totalVisitsLeft;
  final int? totalConsultationsLeft;
  final double? consultationAmountLeft;

  const InsureePolicy({
    required this.code,
    required this.name,
    required this.status,
    this.expiryDate,
    this.ceilingOp,
    this.ceilingIp,
    this.deductibleOp,
    this.deductibleIp,
    this.totalVisitsLeft,
    this.totalConsultationsLeft,
    this.consultationAmountLeft,
  });

  bool get isActive =>
      status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'READY';

  factory InsureePolicy.fromJson(Map<String, dynamic> json) {
    return InsureePolicy(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Standard Health Policy',
      status: json['status']?.toString() ?? 'ACTIVE',
      expiryDate:
          json['expiryDate']?.toString() ?? json['validityTo']?.toString(),
      ceilingOp: (json['ceilingOp'] as num?)?.toDouble(),
      ceilingIp: (json['ceilingIp'] as num?)?.toDouble(),
      deductibleOp: (json['deductibleOp'] as num?)?.toDouble(),
      deductibleIp: (json['deductibleIp'] as num?)?.toDouble(),
      totalVisitsLeft: (json['totalVisitsLeft'] as num?)?.toInt(),
      totalConsultationsLeft: (json['totalConsultationsLeft'] as num?)?.toInt(),
      consultationAmountLeft: (json['consultationAmountLeft'] as num?)
          ?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'status': status,
    'expiryDate': expiryDate,
    'ceilingOp': ceilingOp,
    'ceilingIp': ceilingIp,
    'deductibleOp': deductibleOp,
    'deductibleIp': deductibleIp,
    'totalVisitsLeft': totalVisitsLeft,
    'totalConsultationsLeft': totalConsultationsLeft,
    'consultationAmountLeft': consultationAmountLeft,
  };
}
