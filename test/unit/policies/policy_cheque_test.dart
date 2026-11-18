import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_cheque.dart';
import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';

void main() {
  const cheques = [
    CsuMasterDataRecord({
      'chequeImportLineCode': 'CC240524',
      'chequeImportLineStatus': 'New',
    }),
    CsuMasterDataRecord({
      'chequeImportLineCode': 'CC240523',
      'chequeImportLineStatus': 'Used',
    }),
  ];

  test('accepts only a case-sensitive New cheque', () {
    expect(PolicyCheque.validate('CC240524', cheques), isNull);
    expect(
      PolicyCheque.validate('CC240523', cheques),
      'Chèque CC240523 déjà utilisé',
    );
    expect(
      PolicyCheque.validate('ZZ999999', cheques),
      "Le chèque ZZ999999 n'existe pas dans le système",
    );
    expect(
      PolicyCheque.validate('cc240524', cheques),
      "Le chèque cc240524 n'existe pas dans le système",
    );
  });
}
