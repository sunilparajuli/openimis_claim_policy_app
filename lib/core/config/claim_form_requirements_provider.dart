import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ClaimFormRequirements {
  const ClaimFormRequirements({
    this.guaranteeNumber = false,
    this.secondaryDiagnosis = false,
    this.medicalService = false,
    this.medicalItem = false,
  });

  final bool guaranteeNumber;
  final bool secondaryDiagnosis;
  final bool medicalService;
  final bool medicalItem;

  ClaimFormRequirements copyWith({
    bool? guaranteeNumber,
    bool? secondaryDiagnosis,
    bool? medicalService,
    bool? medicalItem,
  }) => ClaimFormRequirements(
    guaranteeNumber: guaranteeNumber ?? this.guaranteeNumber,
    secondaryDiagnosis: secondaryDiagnosis ?? this.secondaryDiagnosis,
    medicalService: medicalService ?? this.medicalService,
    medicalItem: medicalItem ?? this.medicalItem,
  );

  Map<String, dynamic> toJson() => {
    'guaranteeNumber': guaranteeNumber,
    'secondaryDiagnosis': secondaryDiagnosis,
    'medicalService': medicalService,
    'medicalItem': medicalItem,
  };

  factory ClaimFormRequirements.fromJson(Map<String, dynamic> json) =>
      ClaimFormRequirements(
        guaranteeNumber: json['guaranteeNumber'] == true,
        secondaryDiagnosis: json['secondaryDiagnosis'] == true,
        medicalService: json['medicalService'] == true,
        medicalItem: json['medicalItem'] == true,
      );
}

final claimRequirementsStorageProvider = Provider(
  (ref) => const FlutterSecureStorage(),
);

final claimFormRequirementsProvider =
    AsyncNotifierProvider<ClaimFormRequirementsNotifier, ClaimFormRequirements>(
      ClaimFormRequirementsNotifier.new,
    );

class ClaimFormRequirementsNotifier
    extends AsyncNotifier<ClaimFormRequirements> {
  static const _storageKey = 'claim_form_requirements';

  @override
  Future<ClaimFormRequirements> build() async {
    final value = await ref
        .read(claimRequirementsStorageProvider)
        .read(key: _storageKey);
    if (value == null || value.isEmpty) return const ClaimFormRequirements();
    try {
      return ClaimFormRequirements.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
    } catch (_) {
      return const ClaimFormRequirements();
    }
  }

  Future<void> save(ClaimFormRequirements requirements) async {
    state = AsyncData(requirements);
    await ref
        .read(claimRequirementsStorageProvider)
        .write(key: _storageKey, value: jsonEncode(requirements.toJson()));
  }
}
