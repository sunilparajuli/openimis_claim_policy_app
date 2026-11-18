import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';

class PolicyProduct {
  const PolicyProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.programCode,
    this.minAge = 0,
    this.maxAge = 0,
  });

  final int id;
  final String code;
  final String name;
  final String programCode;
  final int minAge;
  final int maxAge;

  bool get isChequeSante => programCode.toUpperCase() == 'CCS';
  bool get isHiv => programCode.toUpperCase() == 'VIH';

  factory PolicyProduct.fromMasterData(
    CsuMasterDataRecord record, {
    Iterable<CsuMasterDataRecord> programs = const [],
  }) {
    final id = record.id;
    if (id == null) {
      throw FormatException(
        'Product ${record.code ?? record.name ?? ''} has no server ID.',
      );
    }
    final rawProgram = record.program ?? '';
    final programId = int.tryParse(rawProgram);
    final resolvedProgram = programId == null
        ? null
        : programs
              .where((program) => program.id == programId)
              .firstOrNull
              ?.code;
    return PolicyProduct(
      id: id,
      code: record.code ?? '',
      name: record.name ?? record.code ?? '',
      programCode: resolvedProgram ?? rawProgram,
      minAge: record.minAge,
      maxAge: record.maxAge,
    );
  }

  ProductEligibility eligibility(DateTime dateOfBirth, DateTime startDate) {
    final age = ageOn(dateOfBirth, startDate);
    if (minAge > 0 && age < minAge) {
      return ProductEligibility(
        allowed: false,
        message: 'The beneficiary has not reached the minimum age of $minAge.',
      );
    }
    if (maxAge > 0 && age >= maxAge) {
      return ProductEligibility(
        allowed: false,
        message: 'The beneficiary has exceeded the maximum age of $maxAge.',
      );
    }
    return const ProductEligibility(allowed: true);
  }

  /// Policies cannot run beyond the beneficiary's limiting birthday.
  DateTime cappedExpiry(
    DateTime dateOfBirth,
    DateTime startDate,
    DateTime requestedExpiry,
  ) {
    final check = eligibility(dateOfBirth, startDate);
    if (!check.allowed) {
      throw FormatException(check.message ?? 'Product age limit not met.');
    }
    if (maxAge == 0) return requestedExpiry;
    final limitingBirthday = birthday(dateOfBirth, maxAge);
    return requestedExpiry.isAfter(limitingBirthday)
        ? limitingBirthday
        : requestedExpiry;
  }

  static int ageOn(DateTime dateOfBirth, DateTime onDate) {
    var age = onDate.year - dateOfBirth.year;
    if (onDate.month < dateOfBirth.month ||
        (onDate.month == dateOfBirth.month && onDate.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  static DateTime birthday(DateTime dateOfBirth, int age) {
    final year = dateOfBirth.year + age;
    final lastDay = DateTime(year, dateOfBirth.month + 1, 0).day;
    return DateTime(year, dateOfBirth.month, dateOfBirth.day.clamp(1, lastDay));
  }
}

class ProductEligibility {
  const ProductEligibility({required this.allowed, this.message});

  final bool allowed;
  final String? message;
}
