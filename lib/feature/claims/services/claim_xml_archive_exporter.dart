import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';

class ClaimXmlArchiveExporter {
  const ClaimXmlArchiveExporter({
    this.password = const String.fromEnvironment('CLAIMS_ARCHIVE_PASSWORD'),
  });

  final String password;

  Uint8List export(Iterable<ClaimSubmission> claims) {
    if (password.isEmpty) {
      throw StateError(
        'The build-config claim archive password is not configured.',
      );
    }
    final values = claims.toList(growable: false);
    if (values.isEmpty) {
      throw const FormatException('Select at least one claim to export.');
    }
    final archive = Archive();
    for (final claim in values) {
      archive.addFile(ArchiveFile.string(_fileName(claim), toXml(claim)));
    }
    return Uint8List.fromList(ZipEncoder(password: password).encode(archive));
  }

  String toXml(ClaimSubmission claim) {
    final secondary = claim.secondaryDiagnoses;
    final details = <String, Object?>{
      'ClaimDate': _date(claim.claimDate),
      'HFCode': claim.healthFacility,
      'ClaimAdmin': claim.claimAdmin,
      'ClaimCode': claim.claimCode,
      'Program': claim.program?.code,
      'GuaranteeNumber': claim.guaranteeNo,
      'CHFID': claim.insureeChfId,
      'StartDate': _date(claim.startDate),
      'EndDate': _date(claim.endDate),
      'ICDCode': claim.primaryDiagnosis.code,
      'Comment': 'Mobile Claim Submission',
      'Total': claim.totalAmount.toStringAsFixed(2),
      for (var index = 0; index < 4; index++)
        'ICDCode${index + 1}': index < secondary.length
            ? secondary[index].code
            : null,
      'VisitType': claim.visitType.code,
    };
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Claim>',
    );
    _writeObject(buffer, 'Details', details);
    buffer.write('<Items>');
    for (final entry in claim.items) {
      _writeObject(buffer, 'Item', {
        'ItemCode': entry.item.code,
        'ItemPrice': entry.price.toStringAsFixed(2),
        'ItemQuantity': entry.quantity,
        'ItemId': entry.item.id,
      });
    }
    buffer.write('</Items><Services>');
    for (final entry in claim.services) {
      _writeObject(buffer, 'Service', {
        'ServiceCode': entry.service.code,
        'ServicePrice': entry.price.toStringAsFixed(2),
        'ServiceQuantity': entry.quantity,
        'ServicePackageType': entry.service.category,
        'ServiceId': entry.service.id,
      });
    }
    buffer.write('</Services></Claim>');
    return buffer.toString();
  }

  static void _writeObject(
    StringBuffer output,
    String name,
    Map<String, Object?> values,
  ) {
    output.write('<$name>');
    for (final entry in values.entries) {
      if (entry.value == null) continue;
      output
        ..write('<${entry.key}>')
        ..write(_escape(entry.value.toString()))
        ..write('</${entry.key}>');
    }
    output.write('</$name>');
  }

  static String _escape(String value) =>
      const HtmlEscape(HtmlEscapeMode.element).convert(value);

  static String _date(DateTime value) =>
      value.toIso8601String().substring(0, 10);

  static String _fileName(ClaimSubmission claim) =>
      'Claim_${_safe(claim.healthFacility)}_${_safe(claim.claimCode)}_'
      '${_date(claim.claimDate)}.xml';

  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
}
