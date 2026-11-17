import 'dart:convert';

import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';

/// Server-owned mobile input limits with the documented CSU defaults.
class CsuInputLimits {
  const CsuInputLimits({
    this.mpiMinLength = 12,
    this.mpiMaxLength = 20,
    this.chequeMinLength = 6,
  });

  final int mpiMinLength;
  final int mpiMaxLength;
  final int chequeMinLength;

  factory CsuInputLimits.fromMasterData(CsuMasterData data) {
    final values = <String, int>{};
    for (final record in data.exposedFrontendConfiguration) {
      final key = _normalizedKey(
        record.values['key'] ?? record.values['name'] ?? record.values['code'],
      );
      final value = _intValue(
        record.values['value'] ??
            record.values['configValue'] ??
            record.values['defaultValue'],
      );
      if (key.isNotEmpty && value != null) values[key] = value;

      final config = _configMap(record.values['config']);
      for (final entry in config.entries) {
        final configuredValue = _intValue(entry.value);
        if (configuredValue != null) {
          values[_normalizedKey(entry.key)] = configuredValue;
        }
      }
    }

    int configured(Iterable<String> keys, int fallback) {
      for (final key in keys) {
        final value = values[_normalizedKey(key)];
        if (value != null && value > 0) return value;
      }
      return fallback;
    }

    return CsuInputLimits(
      mpiMinLength: configured(const [
        'mpiMinLength',
        'minChfId',
        'minMpiLength',
        'insureeForm.chfIdMinLength',
      ], 12),
      mpiMaxLength: configured(const [
        'mpiMaxLength',
        'maxChfId',
        'maxMpiLength',
        'insureeForm.chfIdMaxLength',
      ], 20),
      chequeMinLength: configured(const [
        'chequeMinLength',
        'minChequeNumberRequired',
      ], 6),
    );
  }

  String? validateMpi(String mpi) {
    if (mpi.length < mpiMinLength) {
      return 'Insurance Number must contain at least $mpiMinLength characters';
    }
    if (mpi.length > mpiMaxLength) {
      return 'Insurance Number must contain at most $mpiMaxLength characters';
    }
    return null;
  }

  String? validateCheque(String cheque) {
    if (cheque.length < chequeMinLength) {
      return 'Cheque number must contain at least $chequeMinLength characters';
    }
    return null;
  }

  static String _normalizedKey(Object? value) =>
      value?.toString().replaceAll(RegExp('[^A-Za-z0-9]'), '').toLowerCase() ??
      '';

  static int? _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static Map<String, dynamic> _configMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }
}
