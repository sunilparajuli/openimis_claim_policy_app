/// Normalization and validation for CSU MPI/CHFID values.
///
/// Surrounding whitespace and format characters introduced by copy/paste or a
/// scanner are removed. The same invisible characters inside the identifier are
/// rejected so two visually identical insurees cannot be created.
abstract final class InsureeNumber {
  static final RegExp _invisible = RegExp(
    '[\u00AD\u034F\u061C\u115F\u1160\u17B4\u17B5'
    '\u180B-\u180F\u200B-\u200F\u202A-\u202E'
    '\u2060-\u206F\u3164\uFEFF\uFFA0]',
    unicode: true,
  );

  static String normalize(String value) {
    var result = value.trim();
    while (result.isNotEmpty && _invisible.hasMatch(result[0])) {
      result = result.substring(1).trimLeft();
    }
    while (result.isNotEmpty &&
        _invisible.hasMatch(result[result.length - 1])) {
      result = result.substring(0, result.length - 1).trimRight();
    }
    return result;
  }

  static bool containsInvisibleCharacters(String value) {
    return _invisible.hasMatch(normalize(value));
  }

  static InsureeNumberIssue? validate(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return InsureeNumberIssue.required;
    if (containsInvisibleCharacters(normalized)) {
      return InsureeNumberIssue.invisibleCharacter;
    }
    return null;
  }
}

enum InsureeNumberIssue { required, invisibleCharacter }
