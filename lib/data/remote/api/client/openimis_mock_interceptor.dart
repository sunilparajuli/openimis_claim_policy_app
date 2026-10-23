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
                        'code': code,
                        'healthFacility': {
                          'code': 'RAHOS001',
                          'name': 'Rapta District Hospital',
                          'servicesPricelist': {
                            'details': {
                              'edges': [
                                {
                                  'node': {
                                    'service': {
                                      'code': 'A1',
                                      'name': 'Consultation',
                                      'price': 15.0,
                                    },
                                  },
                                },
                                {
                                  'node': {
                                    'service': {
                                      'code': 'LAB01',
                                      'name': 'Blood Analysis',
                                      'price': 8.0,
                                    },
                                  },
                                },
                              ],
                            },
                          },
                          'itemsPricelist': {
                            'details': {
                              'edges': [
                                {
                                  'node': {
                                    'item': {
                                      'code': '0176',
                                      'name': 'Oral Rehydration Salts',
                                      'price': 2.5,
                                    },
                                  },
                                },
                                {
                                  'node': {
                                    'item': {
                                      'code': 'PAR500',
                                      'name': 'Paracetamol 500mg',
                                      'price': 1.0,
                                    },
                                  },
                                },
                              ],
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
