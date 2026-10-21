import 'package:flutter_riverpod_template/data/remote/graphql/graphql_service_provider.dart';
import 'package:flutter_riverpod_template/data/remote/graphql/native_graphql_service.dart';
import 'package:flutter_riverpod_template/feature/insuree/models/insuree_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'insuree_repository.g.dart';

@riverpod
InsureeRepository insureeRepository(Ref ref) {
  final gql = ref.watch(graphQLServiceProvider);
  return InsureeRepository(gql);
}

class InsureeRepository {
  final NativeGraphQLService _gql;

  InsureeRepository(this._gql);

  /// Queries insuree profile, policy validity, and benefit balances using openIMIS GraphQL
  Future<Insuree?> getInsureeByChfId(String chfId) async {
    const query = r'''
      query InsureeProfileQuery($chfid: String!) {
        insureeProfile(insureeCHFID: $chfid) {
          chfId
          fullName
          gender
          dob
          photoUrl
          healthFacility {
            name
          }
          policies {
            code
            name
            status
            expiryDate
            ceilingOp
            ceilingIp
            deductibleOp
            deductibleIp
            totalVisitsLeft
            totalConsultationsLeft
            consultationAmountLeft
          }
        }
      }
    ''';

    final data = await _gql.query(query, variables: {'chfid': chfId});
    final profile = data['insureeProfile'];
    if (profile is Map<String, dynamic>) {
      return Insuree.fromJson(profile);
    }
    return null;
  }
}
