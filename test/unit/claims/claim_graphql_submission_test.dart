import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/data/remote/api/client/openimis_mock_interceptor.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/dio_http_service.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_program.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_master_data.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_service_item_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/diagnosis_model.dart';
import 'package:openimis_claim_policy_app/feature/claims/repositories/claim_repository.dart';

class CaptureInterceptor extends Interceptor {
  CaptureInterceptor({this.mutationError});

  final String? mutationError;
  Map<String, dynamic>? createClaimInput;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.data;
    if (data is Map &&
        data['query']?.toString().contains('MobileClaimMutationStatus') ==
            true &&
        mutationError != null) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'mutationLogs': {
                'edges': [
                  {
                    'node': {'status': 1, 'error': mutationError},
                  },
                ],
              },
            },
          },
        ),
      );
    }
    if (data is Map &&
        data['query']?.toString().contains('CreateMobileClaim') == true) {
      final variables = data['variables'];
      if (variables is Map && variables['input'] is Map) {
        createClaimInput = Map<String, dynamic>.from(variables['input'] as Map);
      }
    }
    handler.next(options);
  }
}

void main() {
  test('recognizes Chèque Santé from the authoritative CCS program code', () {
    expect(
      const ClaimProgram(
        id: '2',
        code: 'CCS',
        name: 'Chèque Santé',
      ).isChequeSante,
      isTrue,
    );
    expect(
      const ClaimProgram(id: '3', code: 'VIH', name: 'VIH').isChequeSante,
      isFalse,
    );
  });

  test('only accepts diagnosis and programme codes from local master data', () {
    final store = ClaimMasterDataStore()
      ..value = const ClaimMasterData(
        administrator: ClaimAdministratorProfile(
          code: 'A1',
          displayName: 'Admin',
          healthFacilityCode: 'HF1',
          healthFacilityName: 'Facility',
        ),
        diagnoses: [Diagnosis(id: '10', code: 'A09', name: 'Diagnosis')],
        services: [],
        items: [],
        programs: [ClaimProgram(id: '2', code: 'CCS', name: 'Chèque Santé')],
      );
    final repository = ClaimRepository(
      DioHttpService(Dio(BaseOptions(baseUrl: 'https://example.test/'))),
      store,
    );

    expect(
      repository.containsDiagnosis(
        const Diagnosis(id: '10', code: 'A09', name: 'Selected'),
      ),
      isTrue,
    );
    expect(
      repository.containsDiagnosis(
        const Diagnosis(id: '11', code: 'A09', name: 'Wrong server ID'),
      ),
      isFalse,
    );
    expect(
      repository.containsProgram(
        const ClaimProgram(id: '2', code: 'CCS', name: 'Selected'),
      ),
      isTrue,
    );
    expect(
      repository.containsProgram(
        const ClaimProgram(id: '3', code: 'CCS', name: 'Wrong server ID'),
      ),
      isFalse,
    );
  });

  test('submits the CSU programme and MOB source through GraphQL', () async {
    final capture = CaptureInterceptor();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'))
      ..interceptors.add(capture)
      ..interceptors.add(const OpenImisMockInterceptor(forceDemo: true));
    final repository = ClaimRepository(DioHttpService(dio));
    final claim = ClaimSubmission(
      claimCode: 'C0000001',
      healthFacility: 'HF1',
      healthFacilityId: '31',
      claimAdmin: 'CA1',
      claimAdminId: '41',
      insureeChfId: '120902348063',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 2),
      claimDate: DateTime(2026, 1, 2),
      visitType: ClaimVisitType.other,
      program: const ClaimProgram(id: '2', code: 'CCS', name: 'Chèque Santé'),
      primaryDiagnosis: const Diagnosis(
        id: '101',
        code: 'A09',
        name: 'Diagnosis',
      ),
      services: [
        ClaimedService(
          service: const MedicalService(
            id: '1001',
            code: 'S1',
            name: 'Service',
            price: 5,
            programCode: 'CCS',
          ),
        ),
      ],
    );

    expect(await repository.submitClaim(claim), isTrue);
    expect(capture.createClaimInput, isNotNull);
    expect(capture.createClaimInput!['program'], 2);
    expect(capture.createClaimInput!['source'], 'MOB');
    expect(capture.createClaimInput!.containsKey('pregnancyAge'), isFalse);
    expect(capture.createClaimInput!['insureeId'], 501);
    expect(capture.createClaimInput!['services'], [
      {'serviceId': 1001, 'priceAsked': 5.0, 'qtyProvided': 1, 'status': 1},
    ]);
  });

  test('duplicate mutation failure is reported as a claim error', () async {
    final capture = CaptureInterceptor(
      mutationError: '[{"detail":"mutation.code_name_duplicated: C0000001"}]',
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'))
      ..interceptors.add(capture)
      ..interceptors.add(const OpenImisMockInterceptor(forceDemo: true));
    final repository = ClaimRepository(DioHttpService(dio));
    final claim = ClaimSubmission(
      claimCode: 'C0000001',
      healthFacility: 'HF1',
      healthFacilityId: '31',
      claimAdmin: 'CA1',
      claimAdminId: '41',
      insureeChfId: '120902348063',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 2),
      claimDate: DateTime(2026, 1, 2),
      visitType: ClaimVisitType.other,
      program: const ClaimProgram(id: '2', code: 'CCS', name: 'Chèque Santé'),
      primaryDiagnosis: const Diagnosis(
        id: '101',
        code: 'A09',
        name: 'Diagnosis',
      ),
    );

    await expectLater(
      repository.submitClaim(claim),
      throwsA(
        isA<FormatException>()
            .having(
              (error) => error.message,
              'message',
              contains("Error while creating claim 'C0000001'"),
            )
            .having(
              (error) => error.message,
              'message',
              isNot(contains('creating policy')),
            ),
      ),
    );
  });
}
