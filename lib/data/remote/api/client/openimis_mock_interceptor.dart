import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Local openIMIS responses used only when `DATA_MODE=demo`.
class OpenImisMockInterceptor implements Interceptor {
  const OpenImisMockInterceptor({this.forceDemo = false});

  final bool forceDemo;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final baseUrl = options.baseUrl;
    final isDemoEnvironment =
        forceDemo || baseUrl.isEmpty || options.extra['mock_mode'] == true;

    // Only intercept openIMIS domain endpoints when not connected to a live openIMIS server
    if (!isDemoEnvironment) {
      return handler.next(options);
    }

    if (path.contains('api/tools/extracts/download_master_data')) {
      final masterData = {
        'confirmationTypes': <Object>[],
        'controls': [
          {
            'mobileCapabilities': ['claims', 'policiesCsu', 'policiesHiv'],
          },
        ],
        'education': <Object>[],
        'familyTypes': [
          {'FamilyTypeCode': 'N', 'FamilyType': 'Nuclear'},
          {'FamilyTypeCode': 'E', 'FamilyType': 'Extended'},
        ],
        'hf': [
          {'code': 'RAHOS001', 'name': 'Rapta District Hospital'},
        ],
        'identificationTypes': <Object>[],
        'languages': [
          {'code': 'fr', 'name': 'Français'},
          {'code': 'en', 'name': 'English'},
        ],
        'locations': [
          {
            'LocationId': 101,
            'LocationCode': 'DEMO-V',
            'LocationName': 'Demo Village',
            'LocationType': 'V',
          },
        ],
        'officers': [
          {
            'OfficerID': 201,
            'Code': 'DEMO-OFFICER',
            'LastName': 'Officer',
            'OtherNames': 'Demo',
            'LocationId': 101,
          },
        ],
        'payers': <Object>[],
        'products': [
          {
            'ProdID': 301,
            'code': 'CSU',
            'name': 'Couverture Santé Universelle',
            'program': 'CSU',
            'minAge': 0,
            'maxAge': 0,
          },
          {
            'ProdID': 302,
            'code': 'CCS',
            'name': 'Chèque Santé',
            'program': 'CCS',
            'minAge': 0,
            'maxAge': 46,
          },
          {
            'ProdID': 303,
            'code': 'VIH',
            'name': 'Programme VIH',
            'program': 'VIH',
            'minAge': 0,
            'maxAge': 0,
          },
        ],
        'professions': <Object>[],
        'relations': <Object>[],
        'phoneDefaults': <Object>[],
        'genders': [
          {'code': 'M', 'name': 'Male'},
          {'code': 'F', 'name': 'Female'},
        ],
        'programs': [
          {'code': 'CSU', 'name': 'CSU'},
          {'code': 'CCS', 'name': 'Chèque Santé'},
          {'code': 'VIH', 'name': 'VIH'},
        ],
        'cheques': [
          {
            'idChequeImportLine': 401,
            'chequeImportLineCode': 'CC240524',
            'chequeImportLineStatus': 'New',
          },
        ],
        'ModuleConfiguration': [
          {
            'key': 'mpiMinLength',
            'value': 12,
            'layer': 'fe',
            'is_exposed': true,
          },
          {
            'key': 'mpiMaxLength',
            'value': 20,
            'layer': 'fe',
            'is_exposed': true,
          },
          {
            'key': 'chequeMinLength',
            'value': 6,
            'layer': 'fe',
            'is_exposed': true,
          },
        ],
      };
      final archive = Archive()
        ..addFile(ArchiveFile.string('MasterData.txt', jsonEncode(masterData)));
      final bytes = ZipEncoder().encode(archive);
      return handler.resolve(
        Response<List<int>>(
          requestOptions: options,
          statusCode: 200,
          data: bytes,
          headers: Headers.fromMap({
            Headers.contentTypeHeader: ['application/zip'],
          }),
        ),
      );
    }

    if (path.contains('api_fhir_r4/login')) {
      final credentials = options.data is Map ? options.data as Map : const {};
      final username = credentials['username']?.toString() ?? '';
      final password = credentials['password']?.toString() ?? '';
      if (username.isEmpty || password.isEmpty) {
        return handler.reject(
          DioException.badResponse(
            statusCode: 401,
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 401),
          ),
        );
      }
      return handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'token': 'demo-openimis-token-$username',
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 8))
                    .millisecondsSinceEpoch ~/
                1000,
          },
        ),
      );
    }

    if (path.contains('api_fhir_r4/Practitioner')) {
      final code =
          options.queryParameters['identifier']?.toString() ?? 'RHOS0011';
      return handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'resourceType': 'Bundle',
            'entry': [
              {
                'resource': {
                  'resourceType': 'Practitioner',
                  'identifier': [
                    {'value': code},
                  ],
                  'name': [
                    {
                      'family': 'Lawrence',
                      'given': ['Rijo'],
                    },
                  ],
                  'healthFacility': {
                    'code': 'RAHOS001',
                    'name': 'Rapta District Hospital',
                  },
                },
              },
            ],
          },
        ),
      );
    }

    if (path.contains('CodeSystem/diagnosis')) {
      return handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'resourceType': 'CodeSystem',
            'concept': [
              {
                'code': 'A09',
                'display': 'Infectious gastroenteritis and colitis',
              },
              {'code': 'B50.9', 'display': 'Plasmodium falciparum malaria'},
              {'code': 'J18.9', 'display': 'Pneumonia, unspecified organism'},
            ],
          },
        ),
      );
    }

    // 1. FHIR R4 Claim Submission & Retrieval
    if (path.contains('api_fhir_r4/Claim') || path.endsWith('Claim/')) {
      if (kDebugMode) {
        debugPrint(
          '🟢 [openIMIS Mock Server] Intercepted FHIR R4 Claim request: ${options.method} $path',
        );
      }

      if (options.method.toUpperCase() == 'POST') {
        final submissionData = options.data is Map ? options.data as Map : {};
        final claimId =
            submissionData['id'] ??
            'CLM-${DateTime.now().millisecondsSinceEpoch % 100000}';

        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 201,
            statusMessage: 'Created',
            data: {
              'resourceType': 'ClaimResponse',
              'id': 'RESP-$claimId',
              'status': 'active',
              'type': {
                'coding': [
                  {
                    'system':
                        'http://terminology.hl7.org/CodeSystem/claim-type',
                    'code': 'institutional',
                    'display': 'Institutional Healthcare Service',
                  },
                ],
              },
              'use': 'claim',
              'patient': {
                'reference': 'Patient/CHF-9823412',
                'display': 'Insuree Beneficiary',
              },
              'created': DateTime.now().toIso8601String(),
              'outcome': 'complete',
              'disposition': 'Claim accepted by openIMIS FHIR R4 Core engine.',
              'total': [
                {
                  'category': {
                    'coding': [
                      {'code': 'submitted'},
                    ],
                  },
                  'amount': {'value': 48.50, 'currency': 'USD'},
                },
              ],
            },
          ),
        );
      } else {
        // GET Claims
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            statusMessage: 'OK',
            data: {
              'resourceType': 'Bundle',
              'type': 'searchset',
              'total': 3,
              'entry': [
                {
                  'resource': {
                    'resourceType': 'Claim',
                    'id': 'CLM-78401',
                    'status': 'active',
                    'use': 'claim',
                    'created': '2026-10-08',
                  },
                },
              ],
            },
          ),
        );
      }
    }

    // 2. openIMIS GraphQL Queries (Indicators & Analytics)
    if (path.contains('graphql')) {
      if (kDebugMode) {
        debugPrint(
          '🟢 [openIMIS Mock Server] Intercepted GraphQL Query: $path',
        );
      }

      final document = options.data is Map
          ? (options.data as Map)['query']?.toString() ?? ''
          : '';
      if (document.contains('ClaimDiagnoses')) {
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'diagnoses': {
                  'edges': [
                    {
                      'node': {
                        'id': '101',
                        'code': 'A09',
                        'name': 'Infectious gastroenteritis and colitis',
                      },
                    },
                    {
                      'node': {
                        'id': '102',
                        'code': 'B50.9',
                        'name': 'Plasmodium falciparum malaria',
                      },
                    },
                  ],
                },
              },
            },
          ),
        );
      }
      if (document.contains('ClaimInsuree')) {
        final variables = options.data is Map
            ? (options.data as Map)['variables'] as Map?
            : null;
        final chfId = variables?['chfId']?.toString() ?? '';
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'insurees': {
                  'edges': [
                    {
                      'node': {'id': '501', 'chfId': chfId},
                    },
                  ],
                },
              },
            },
          ),
        );
      }
      if (document.contains('ClaimEligibleCatalog')) {
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'medicalServices': {
                  'edges': [
                    {
                      'node': {
                        'id': '1001',
                        'code': 'A1',
                        'name': 'Consultation',
                        'price': 999,
                        'program': {'code': 'CSU'},
                        'healthFacility': {'id': '31', 'code': 'RAHOS001'},
                      },
                    },
                    {
                      'node': {
                        'id': '99001',
                        'code': 'SHARED-CCS',
                        'name': 'Shared Chèque Santé service',
                        'price': 25,
                        'program': {'code': 'CCS'},
                        'healthFacility': null,
                      },
                    },
                  ],
                },
                'medicalItems': {
                  'edges': [
                    {
                      'node': {
                        'id': '2001',
                        'code': '0176',
                        'name': 'Oral Rehydration Salts',
                        'price': 999,
                        'program': {'code': 'CSU'},
                        'healthFacility': {'id': '31', 'code': 'RAHOS001'},
                      },
                    },
                    {
                      'node': {
                        'id': '99002',
                        'code': 'SHARED-ITEM-CCS',
                        'name': 'Shared Chèque Santé item',
                        'price': 3,
                        'program': {'code': 'CCS'},
                        'healthFacility': null,
                      },
                    },
                  ],
                },
              },
            },
          ),
        );
      }
      if (document.contains('CreateMobileClaim')) {
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'createClaim': {
                  'clientMutationId': 'demo-claim',
                  'internalId': 1,
                },
              },
            },
          ),
        );
      }
      if (document.contains('MobileClaimMutationStatus')) {
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'mutationLogs': {
                  'edges': [
                    {
                      'node': {'status': 2, 'error': null},
                    },
                  ],
                },
              },
            },
          ),
        );
      }
      if (document.contains('ClaimPrograms')) {
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'program': {
                  'edges': [
                    {
                      'node': {
                        'idProgram': '1',
                        'code': 'CSU',
                        'nameProgram': 'CSU',
                      },
                    },
                    {
                      'node': {
                        'idProgram': '2',
                        'code': 'CCS',
                        'nameProgram': 'Chèque Santé',
                      },
                    },
                    {
                      'node': {
                        'idProgram': '3',
                        'code': 'VIH',
                        'nameProgram': 'VIH',
                      },
                    },
                  ],
                },
              },
            },
          ),
        );
      }
      if (document.contains('ClaimMobileSetup')) {
        final variables = options.data is Map
            ? (options.data as Map)['variables'] as Map?
            : null;
        final code = variables?['code']?.toString() ?? 'RHOS0011';
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'claimAdmins': {
                  'edges': [
                    {
                      'node': {
                        'id': '41',
                        'code': code,
                        'healthFacility': {
                          'id': '31',
                          'code': 'RAHOS001',
                          'name': 'Rapta District Hospital',
                          'servicesPricelist': {
                            'details': {
                              'edges': List.generate(30000, (index) {
                                final service = switch (index) {
                                  0 => {
                                    'id': '1001',
                                    'code': 'A1',
                                    'name': 'Consultation',
                                    'price': 15.0,
                                  },
                                  1 => {
                                    'id': '1002',
                                    'code': 'LAB01',
                                    'name': 'Blood Analysis',
                                    'price': 8.0,
                                  },
                                  _ => {
                                    'id': '${1000 + index}',
                                    'code':
                                        'SRV-${index.toString().padLeft(5, '0')}',
                                    'name': 'Medical service $index',
                                    'price': (index % 100) + 1.0,
                                  },
                                };
                                return {
                                  'node': {'service': service},
                                };
                              }),
                            },
                          },
                          'itemsPricelist': {
                            'details': {
                              'edges': List.generate(30000, (index) {
                                final item = switch (index) {
                                  0 => {
                                    'id': '2001',
                                    'code': '0176',
                                    'name': 'Oral Rehydration Salts',
                                    'price': 2.5,
                                  },
                                  1 => {
                                    'id': '2002',
                                    'code': 'PAR500',
                                    'name': 'Paracetamol 500mg',
                                    'price': 1.0,
                                  },
                                  _ => {
                                    'id': '${2000 + index}',
                                    'code':
                                        'ITM-${index.toString().padLeft(5, '0')}',
                                    'name': 'Medical item $index',
                                    'price': (index % 100) + 0.5,
                                  },
                                };
                                return {
                                  'node': {'item': item},
                                };
                              }),
                            },
                          },
                        },
                      },
                    },
                  ],
                },
              },
            },
          ),
        );
      }

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          statusMessage: 'OK',
          data: {
            'data': {
              'active': {'totalCount': 1248},
              'expired': {'totalCount': 86},
              'idle': {'totalCount': 12},
              'suspended': {'totalCount': 4},
              'ready': {'totalCount': 35},
              'new': {'totalCount': 14},
              'renewed': {'totalCount': 28},
            },
          },
        ),
      );
    }

    // 3. openIMIS Policy & Commission REST endpoints
    if (path.contains('policy/commissions')) {
      if (kDebugMode) {
        debugPrint(
          '🟢 [openIMIS Mock Server] Intercepted Commissions Request: $path',
        );
      }

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          statusMessage: 'OK',
          data: [
            {
              'officerCode': 'OFF-4029',
              'policiesEnrolled': 14,
              'policiesRenewed': 28,
              'ratePerPolicy': 5.0,
              'totalCommission': 252.0,
            },
          ],
        ),
      );
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
}
