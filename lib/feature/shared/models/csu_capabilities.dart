import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';

class CsuCapabilities {
  const CsuCapabilities({
    required this.claims,
    required this.policiesCsu,
    required this.policiesHiv,
  });

  final bool claims;
  final bool policiesCsu;
  final bool policiesHiv;

  factory CsuCapabilities.fromMasterData(CsuMasterData data) {
    final explicit = <String>{};
    for (final control in data.records('controls')) {
      final values = control.values;
      final configured = values['mobileCapabilities'];
      if (configured is List) {
        explicit.addAll(configured.map((value) => _normalize(value)));
      }
      for (final entry in values.entries) {
        if (_isTrue(entry.value)) explicit.add(_normalize(entry.key));
      }
    }

    final programs = data.programs
        .map((record) => _normalize(record.values.values.join(' ')))
        .toList(growable: false);
    final hasExplicitCapabilities = explicit.any(
      (value) => const {'claims', 'policiescsu', 'policieshiv'}.contains(value),
    );
    if (hasExplicitCapabilities) {
      return CsuCapabilities(
        claims: explicit.contains('claims'),
        policiesCsu: explicit.contains('policiescsu'),
        policiesHiv: explicit.contains('policieshiv'),
      );
    }

    final hasHiv = programs.any(
      (program) => program.contains('hiv') || program.contains('vih'),
    );
    return CsuCapabilities(
      claims: data.records('hf').isNotEmpty,
      policiesCsu: programs.any(
        (program) => !program.contains('hiv') && !program.contains('vih'),
      ),
      policiesHiv: hasHiv,
    );
  }

  static String _normalize(Object? value) =>
      value.toString().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  static bool _isTrue(Object? value) =>
      value == true || value?.toString().toLowerCase() == 'true';
}
