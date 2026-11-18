import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_product.dart';
import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';

void main() {
  const product = PolicyProduct(
    id: 1,
    code: 'P1',
    name: 'Age-limited product',
    programCode: 'CSU',
    minAge: 6,
    maxAge: 46,
  );

  test('parses the backend master-data product field names', () {
    final parsed = PolicyProduct.fromMasterData(
      const CsuMasterDataRecord({
        'ProdID': 12,
        'ProductCode': 'CCS1',
        'ProductName': 'Chèque Santé',
        'program': 'CCS',
        'minAge': 6,
        'maxAge': 46,
      }),
    );
    expect(parsed.id, 12);
    expect(parsed.code, 'CCS1');
    expect(parsed.isChequeSante, isTrue);
  });

  test('resolves the exported numeric product programme ID', () {
    final parsed = PolicyProduct.fromMasterData(
      const CsuMasterDataRecord({
        'ProdID': 12,
        'ProductCode': 'VIH1',
        'ProductName': 'HIV',
        'program': 9,
      }),
      programs: const [
        CsuMasterDataRecord({
          'idProgram': 9,
          'programCode': 'VIH',
          'Name': 'HIV',
        }),
      ],
    );
    expect(parsed.programCode, 'VIH');
    expect(parsed.isHiv, isTrue);
  });

  test('rejects beneficiaries below minimum or at maximum age', () {
    final start = DateTime(2026, 1, 1);
    expect(product.eligibility(DateTime(2023, 1, 1), start).allowed, isFalse);
    expect(product.eligibility(DateTime(1976, 1, 1), start).allowed, isFalse);
    expect(product.eligibility(DateTime(1981, 6, 1), start).allowed, isTrue);
  });

  test('caps expiry at the maximum-age birthday', () {
    final dob = DateTime(1981, 6, 15);
    final expiry = product.cappedExpiry(
      dob,
      DateTime(2026, 1, 1),
      DateTime(2027, 12, 31),
    );
    expect(expiry, DateTime(2027, 6, 15));
  });

  test('zero age limits do not restrict eligibility or expiry', () {
    const unlimited = PolicyProduct(
      id: 2,
      code: 'P2',
      name: 'Unlimited',
      programCode: 'CSU',
    );
    final requested = DateTime(2030, 1, 1);
    expect(
      unlimited.cappedExpiry(
        DateTime(1900, 1, 1),
        DateTime(2026, 1, 1),
        requested,
      ),
      requested,
    );
  });
}
