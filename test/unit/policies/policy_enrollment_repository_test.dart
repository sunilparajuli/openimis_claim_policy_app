import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/dio_http_service.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/policies/repositories/policy_enrollment_repository.dart';

class PolicyContractInterceptor extends Interceptor {
  final inputs = <String, Map<String, dynamic>>{};
  int statusRequests = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final body = Map<String, dynamic>.from(options.data as Map);
    final query = body['query'].toString();
    final variables = Map<String, dynamic>.from(body['variables'] as Map);
    if (query.contains('MobileMutationStatus')) {
      statusRequests++;
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'mutationLogs': {
                'edges': [
                  {
                    'node': {'status': statusRequests == 1 ? 0 : 2},
                  },
                ],
              },
            },
          },
        ),
      );
    }
    if (query.contains('MobileFamilyByHead')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'families': {
                'edges': [
                  {
                    'node': {
                      'id': 'RmFtaWx5R1FMVHlwZTo0Mg==',
                      'legacyId': 42,
                      'uuid': 'family-uuid',
                    },
                  },
                ],
              },
            },
          },
        ),
      );
    }
    if (query.contains('MobileInsureeExists')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'insurees': {
                'edges': [
                  {
                    'node': {'id': '1', 'chfId': variables['chfId']},
                  },
                ],
              },
            },
          },
        ),
      );
    }
    if (query.contains('MobileInsureeForEdit')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'insurees': {
                'edges': [
                  {
                    'node': {
                      'uuid': 'insuree-uuid',
                      'chfId': 'TARV-1',
                      'lastName': 'Doe',
                      'otherNames': 'Jane',
                      'dob': '1990-01-02',
                      'head': true,
                      'email': hivInsureeMarkerEmail,
                      'cardIssued': false,
                      'gender': {'code': 'F'},
                      'family': {'legacyId': 42, 'uuid': 'family-uuid'},
                    },
                  },
                ],
              },
            },
          },
        ),
      );
    }
    if (query.contains('MobileFamilyPolicies')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'policiesByFamily': {
                'edges': [
                  {
                    'node': {'productCode': 'CCS1', 'status': 2},
                  },
                ],
              },
            },
          },
        ),
      );
    }
    final field = query.contains('CreateMobileFamily')
        ? 'createFamily'
        : query.contains('CreateMobileInsuree')
        ? 'createInsuree'
        : query.contains('UpdateMobileInsuree')
        ? 'updateInsuree'
        : 'createPolicy';
    inputs[field] = Map<String, dynamic>.from(variables['input'] as Map);
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'data': {
            field: {
              'clientMutationId': inputs[field]!['clientMutationId'],
              'internalId': 91,
            },
          },
        },
      ),
    );
  }
}

void main() {
  late PolicyContractInterceptor capture;
  late PolicyEnrollmentRepository repository;

  setUp(() {
    capture = PolicyContractInterceptor();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'))
      ..interceptors.add(capture);
    repository = PolicyEnrollmentRepository(
      NativeGraphQLService(DioHttpService(dio)),
    );
  });

  test('creates CSU family using the backend family-head contract', () async {
    final result = await repository.createFamily(
      PolicyFamilyDraft(
        application: PolicyApplication.csu,
        locationId: 7,
        poverty: true,
        familyTypeId: 'N',
        head: PolicyInsureeDraft(
          chfId: ' 120902348063480 ',
          lastName: 'Doe',
          otherNames: 'Jane',
          genderId: 'F',
          dateOfBirth: DateTime(1990, 2, 3),
          isHead: true,
        ),
      ),
      clientMutationId: 'family-1',
    );

    expect(result.internalId, 91);
    final input = capture.inputs['createFamily']!;
    expect(input['locationId'], 7);
    expect(input['isOffline'], isTrue);
    expect(input['headInsuree'], containsPair('chfId', '120902348063480'));
    expect((input['headInsuree'] as Map).containsKey('email'), isFalse);
  });

  test('HIV enrolment adds marker and refuses an all-numeric MPI', () async {
    final alphaNumeric = PolicyInsureeDraft(
      chfId: 'TARV-1209',
      lastName: 'Doe',
      otherNames: 'John',
      genderId: 'M',
      dateOfBirth: DateTime(1985, 1, 1),
    );
    await repository.createInsuree(
      alphaNumeric,
      application: PolicyApplication.hiv,
      familyId: 3,
      clientMutationId: 'hiv-1',
    );
    expect(capture.inputs['createInsuree']!['email'], hivInsureeMarkerEmail);

    expect(
      () => PolicyInsureeDraft(
        chfId: '120902348063480',
        lastName: 'Doe',
        otherNames: 'John',
        genderId: 'M',
        dateOfBirth: DateTime(1985, 1, 1),
      ).validatedChfId(PolicyApplication.hiv),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'mutation.insuree.mpi_entirely_numeric_error',
        ),
      ),
    );
  });

  test('creates Chèque Santé policy with pregnancy age', () async {
    await repository.createPolicy(
      PolicyDraft(
        familyId: 3,
        enrolmentDate: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 2),
        expiryDate: DateTime(2026, 12, 31),
        value: 1000,
        productId: 8,
        officerId: 9,
        productCode: 'CCS1',
        policyNumber: 'CC240524',
        pregnancyAge: 30,
        isChequeSante: true,
      ),
      clientMutationId: 'policy-1',
    );

    final input = capture.inputs['createPolicy']!;
    expect(input['policyNumber'], 'CC240524');
    expect(input['pregnancyAge'], 30);
    expect(input['familyId'], 3);
  });

  test('requires pregnancy week 1 to 42 for Chèque Santé', () {
    expect(
      () => PolicyDraft(
        familyId: 3,
        enrolmentDate: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 2),
        expiryDate: DateTime(2026, 12, 31),
        value: 1000,
        productId: 8,
        officerId: 9,
        isChequeSante: true,
      ).toGraphQLInput('policy-1'),
      throwsFormatException,
    );
  });

  test(
    'polls numeric MutationLog status and resolves created family ID',
    () async {
      final status = await repository.waitForMutation(
        'family-1',
        interval: Duration.zero,
        timeout: const Duration(seconds: 1),
      );
      expect(status.succeeded, isTrue);
      expect(capture.statusRequests, 2);
      expect(await repository.familyIdForHead('TARV-1'), 42);
    },
  );

  test('detects existing insurees and policies for retry safety', () async {
    expect(await repository.insureeExists('TARV-2'), isTrue);
    expect(
      await repository.policyExistsForFamily('family-uuid', 'CCS1'),
      isTrue,
    );
    expect(
      await repository.policyExistsForFamily('family-uuid', 'OTHER'),
      isFalse,
    );
  });

  test('loads and updates HIV date of birth and gender', () async {
    final existing = await repository.insureeForEdit(
      'TARV-1',
      application: PolicyApplication.hiv,
    );
    expect(existing.uuid, 'insuree-uuid');
    expect(existing.genderId, 'F');
    expect(existing.dateOfBirth, DateTime(1990, 1, 2));

    final changed = PolicyInsureeDraft(
      uuid: existing.uuid,
      chfId: existing.chfId,
      lastName: existing.lastName,
      otherNames: existing.otherNames,
      genderId: 'M',
      dateOfBirth: DateTime(1991, 3, 4),
      familyId: existing.familyId,
      isHead: existing.isHead,
    );
    await repository.updateInsuree(
      changed,
      application: PolicyApplication.hiv,
      clientMutationId: 'update-hiv-1',
    );
    final input = capture.inputs['updateInsuree']!;
    expect(input['uuid'], 'insuree-uuid');
    expect(input['dob'], '1991-03-04');
    expect(input['genderId'], 'M');
    expect(input['email'], hivInsureeMarkerEmail);
  });
}
