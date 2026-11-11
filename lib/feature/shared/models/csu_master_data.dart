/// The CSU server's downloaded master-data document.
///
/// Values are retained in their source JSON shape because the backend owns
/// these schemas. The app exposes record helpers for the sections used by
/// claims and policy workflows without discarding other documented sections.
class CsuMasterData {
  CsuMasterData._(this._values);

  static const requiredSections = <String>[
    'confirmationTypes',
    'controls',
    'education',
    'familyTypes',
    'hf',
    'identificationTypes',
    'languages',
    'locations',
    'officers',
    'payers',
    'products',
    'professions',
    'relations',
    'phoneDefaults',
    'genders',
    'programs',
    'cheques',
    'ModuleConfiguration',
  ];

  final Map<String, dynamic> _values;

  factory CsuMasterData.fromJson(Map<String, dynamic> json) {
    final missing = requiredSections.where((key) => !json.containsKey(key));
    if (missing.isNotEmpty) {
      throw FormatException(
        'Master data is missing required sections: ${missing.join(', ')}',
      );
    }
    final values = Map<String, dynamic>.from(json);
    values['ModuleConfiguration'] = _onlyExposedFrontendConfiguration(
      values['ModuleConfiguration'],
    );
    return CsuMasterData._(Map<String, dynamic>.unmodifiable(values));
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_values);

  Object? section(String key) => _values[key];

  /// Read list or object-map sections without assuming one backend encoding.
  List<CsuMasterDataRecord> records(String key) {
    final section = _values[key];
    if (section is List) {
      return section
          .whereType<Map>()
          .map((entry) => CsuMasterDataRecord(_stringMap(entry)))
          .toList(growable: false);
    }
    if (section is Map) {
      return section.entries
          .where((entry) => entry.value is Map)
          .map((entry) {
            final value = _stringMap(entry.value as Map);
            value.putIfAbsent('code', () => entry.key.toString());
            return CsuMasterDataRecord(Map.unmodifiable(value));
          })
          .toList(growable: false);
    }
    return const [];
  }

  List<CsuMasterDataRecord> get products => records('products');
  List<CsuMasterDataRecord> get programs => records('programs');
  List<CsuMasterDataRecord> get cheques => records('cheques');

  /// Only exposed frontend settings are available to app workflows.
  List<CsuMasterDataRecord> get exposedFrontendConfiguration =>
      records('ModuleConfiguration')
          .toList(growable: false);

  static bool _isTrue(Object? value) =>
      value == true || value?.toString().toLowerCase() == 'true';

  static Object? _onlyExposedFrontendConfiguration(Object? value) {
    bool isExposedFrontend(Object? candidate) =>
        candidate is Map &&
        candidate['layer']?.toString().toLowerCase() == 'fe' &&
        _isTrue(candidate['is_exposed']);

    if (value is List) {
      return value.where(isExposedFrontend).toList(growable: false);
    }
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries
            .where((entry) => isExposedFrontend(entry.value))
            .map((entry) => MapEntry(entry.key.toString(), entry.value)),
      );
    }
    return const [];
  }

  static Map<String, dynamic> _stringMap(Map value) => {
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
}

/// A backend record whose unrecognized fields remain available in [values].
class CsuMasterDataRecord {
  const CsuMasterDataRecord(this.values);

  final Map<String, dynamic> values;

  Object? operator [](String key) => values[key];

  String? get code => values['code']?.toString();
  String? get program => values['program']?.toString();

  /// In CSU product rules, zero means there is no age limit.
  int get minAge => _asInt(values['minAge']);
  int get maxAge => _asInt(values['maxAge']);

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
