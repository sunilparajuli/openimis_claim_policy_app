import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';

class PolicyCheque {
  const PolicyCheque({required this.code, required this.status});

  final String code;
  final String status;

  factory PolicyCheque.fromMasterData(CsuMasterDataRecord record) =>
      PolicyCheque(
        code:
            record.values['chequeImportLineCode']?.toString() ??
            record.code ??
            '',
        status:
            record.values['chequeImportLineStatus']?.toString() ??
            record.values['status']?.toString() ??
            '',
      );

  static String? validate(String value, Iterable<CsuMasterDataRecord> records) {
    final code = value.trim();
    final cheque = records
        .map(PolicyCheque.fromMasterData)
        .where((item) => item.code == code)
        .firstOrNull;
    if (cheque == null) {
      return "Le chèque $code n'existe pas dans le système";
    }
    if (cheque.status == 'Used') return 'Chèque $code déjà utilisé';
    if (cheque.status != 'New') return 'Chèque $code invalide';
    return null;
  }
}
