import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/insuree/presentation/insuree_qr_scanner_page.dart';

void main() {
  test(
    'accepts and normalizes the raw MPI used by legacy insuree QR codes',
    () {
      expect(InsureeQrPayload.parse(' 120902348063480 '), '120902348063480');
      expect(
        InsureeQrPayload.parse('\u200B120902348063480\u200B'),
        '120902348063480',
      );
      expect(InsureeQrPayload.parse('TARV-001'), 'TARV-001');
    },
  );

  test('rejects empty or visually ambiguous QR payloads', () {
    expect(InsureeQrPayload.parse(null), isNull);
    expect(InsureeQrPayload.parse('   '), isNull);
    expect(InsureeQrPayload.parse('1209\u200B02348063480'), isNull);
  });
}
