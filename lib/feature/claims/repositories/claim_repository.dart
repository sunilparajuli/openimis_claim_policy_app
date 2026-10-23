import 'package:openimis_claim_policy_app/data/remote/api/providers/http_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/http_service.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_service_item_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_master_data.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/diagnosis_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_setup_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';

part 'claim_repository.g.dart';

@riverpod
ClaimRepository claimRepository(Ref ref) {
  final http = ref.watch(httpServiceProvider);
  return ClaimRepository(http, ref.watch(claimMasterDataStoreProvider));
}

class ClaimRepository {
  final HttpService _http;

  ClaimRepository(this._http, [ClaimMasterDataStore? masterData])
    : _masterData = masterData ?? ClaimMasterDataStore();

  final ClaimMasterDataStore _masterData;

  /// Submits a new Claim to openIMIS FHIR R4 endpoint
  Future<bool> submitClaim(ClaimSubmission claim) async {
    final response = await _http.post<Map<String, dynamic>>(
      'api/api_fhir_r4/Claim/',
      data: claim.toFhirJson(),
      options: Options(extra: const {'no_retry': true}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Master list of diagnoses (ICD-10)
  List<Diagnosis> getDiagnoses() {
    final synchronized = _masterData.value?.diagnoses;
    if (synchronized != null && synchronized.isNotEmpty) return synchronized;
    return const [
      Diagnosis(code: 'A09', name: 'Infectious gastroenteritis and colitis'),
      Diagnosis(
        code: 'B50.9',
        name: 'Plasmodium falciparum malaria, unspecified',
      ),
      Diagnosis(code: 'J00', name: 'Acute nasopharyngitis [common cold]'),
      Diagnosis(code: 'J18.9', name: 'Pneumonia, unspecified organism'),
      Diagnosis(code: 'I10', name: 'Essential (primary) hypertension'),
      Diagnosis(
        code: 'E11.9',
        name: 'Type 2 diabetes mellitus without complications',
      ),
      Diagnosis(code: 'K29.7', name: 'Gastritis, unspecified'),
      Diagnosis(code: 'O80', name: 'Single spontaneous delivery'),
      Diagnosis(code: 'R50.9', name: 'Fever, unspecified'),
      Diagnosis(code: 'S09.9', name: 'Unspecified injury of head'),
    ];
  }

  /// Master list of medical services
  List<MedicalService> getAvailableServices() {
    final synchronized = _masterData.value?.services;
    return synchronized ?? const [];
  }

  /// Master list of medications and pharmaceuticals
  List<MedicationItem> getAvailableItems() {
    final synchronized = _masterData.value?.items;
    return synchronized ?? const [];
  }
}
