import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/data/remote/api/providers/http_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/http_service.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/graphql_service_provider.dart';
import 'package:openimis_claim_policy_app/data/remote/graphql/native_graphql_service.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(
    ref.watch(graphQLServiceProvider),
    ref.watch(httpServiceProvider),
  ),
);

/// Request contracts ported from the Policies Android application's reports.
class ReportRepository {
  ReportRepository(this.graphql, this.http);
  final NativeGraphQLService graphql;
  final HttpService http;

  static String date(DateTime value) =>
      value.toIso8601String().substring(0, 10);

  Future<Map<String, num>> indicators(
    String officer,
    DateTime from, {
    DateTime? to,
  }) async {
    final cumulative = to != null;
    final data = await graphql.query(
      cumulative ? cumulativeQuery : snapshotQuery,
      variables: {
        'officerCode': officer,
        if (cumulative) ...{
          'from': date(from),
          'to': date(to),
        } else
          'date': date(from),
      },
    );
    final keys = cumulative
        ? ['new', 'renewed', 'expired', 'suspended']
        : ['active', 'expired', 'idle', 'suspended', 'ready'];
    return {for (final key in keys) key: _count(data, key)};
  }

  num _count(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! Map || value['totalCount'] is! num) {
      throw const FormatException('The report response is incomplete.');
    }
    return value['totalCount'] as num;
  }

  Future<List<Map<String, dynamic>>> commission({
    required String officer,
    required int month,
    required int year,
    required String product,
    required String payer,
    required bool paid,
  }) async {
    final response = await http.post<dynamic>(
      'rest/api/policy/commissions',
      options: Options(headers: {'api-version': '3'}),
      data: {
        'enrolment_officer_code': officer,
        'month': month,
        'year': year,
        // Spelling is part of the legacy API contract.
        'insrance_product_code': product,
        'payer': payer,
        'mode': paid ? '1' : '0',
      },
    );
    final body = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (body is! Map) {
      throw const FormatException('Invalid commission response.');
    }
    if (body['errorOccured'].toString() == 'true') {
      throw FormatException(
        body['messageValue']?.toString() ?? 'Commission lookup failed.',
      );
    }
    final raw = body['data'];
    final rows = raw is String ? jsonDecode(raw) : raw;
    if (rows is! List) {
      throw const FormatException('Invalid commission records.');
    }
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  static const snapshotQuery = r'''
query GetSnapshotPolicies($officerCode: String, $date: Date) {
  idle:policies(startDate_Lte:$date, expiryDate_Gte:$date, officer_Code:$officerCode, status:1) { totalCount }
  active:policies(startDate_Lte:$date, expiryDate_Gte:$date, officer_Code:$officerCode, status:2) { totalCount }
  suspended:policies(startDate_Lte:$date, expiryDate_Gte:$date, officer_Code:$officerCode, status:4) { totalCount }
  expired:policies(expiryDate:$date, officer_Code:$officerCode, status:8) { totalCount }
  ready:policies(startDate_Lte:$date, expiryDate_Gte:$date, officer_Code:$officerCode, status:16) { totalCount }
}''';
  static const cumulativeQuery = r'''
query GetCumulativePolicies($officerCode: String, $from: Date, $to: Date) {
  new:policies(startDate_Lte:$from, expiryDate_Gte:$to, officer_Code:$officerCode, status:2, stage:"n") { totalCount }
  renewed:policies(startDate_Lte:$from, expiryDate_Gte:$to, officer_Code:$officerCode, status:2, stage:"r") { totalCount }
  suspended:policies(startDate_Lte:$from, expiryDate_Gte:$to, officer_Code:$officerCode, status:4) { totalCount }
  expired:policies(startDate_Lte:$from, expiryDate_Gte:$to, officer_Code:$officerCode, status:8) { totalCount }
}''';
}
