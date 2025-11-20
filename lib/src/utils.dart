/// Utility classes and functions for TOON encoding/decoding operations.

/// Exception thrown during TOON encoding or decoding operations.
///
/// This exception is thrown when:
/// - Invalid TOON syntax is encountered (strict mode)
/// - Array length mismatches occur (strict mode)
/// - Delimiter inconsistencies are found (strict mode)
/// - Invalid escape sequences are encountered
class ToonException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Creates a new TOON exception with the given error message.
  ToonException(this.message);

  @override
  String toString() => 'ToonException: $message';
}

// ============================================================================
// String Manipulation Utilities
// ============================================================================

/// Escapes special characters in a string for TOON format.
///
/// Escapes: backslash, quotes, newlines, carriage returns, tabs
String escapeString(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}

/// Unescapes special characters from a TOON string.
///
/// Reverses the escaping done by [escapeString]
String unescapeString(String value) {
  return value
      .replaceAll('\\n', '\n')
      .replaceAll('\\r', '\r')
      .replaceAll('\\t', '\t')
      .replaceAll('\\"', '"')
      .replaceAll('\\\\', '\\');
}

/// Quotes a string if necessary for TOON format.
///
/// Adds quotes around strings that contain special characters or
/// look like other data types (numbers, booleans, etc.)
String quoteString(String value, String delimiter) {
  if (needsQuoting(value, delimiter)) {
    return '"${escapeString(value)}"';
  }
  return value;
}

/// Removes quotes from a TOON string if present.
///
/// Also unescapes any escape sequences in the string
String unquoteString(String value) {
  final trimmed = value.trim();

  if (trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')) {
    return unescapeString(trimmed.substring(1, trimmed.length - 1));
  }

  return trimmed;
}

/// Checks if a string needs to be quoted in TOON format.
///
/// Returns true if the string:
/// - Is empty
/// - Has leading/trailing spaces
/// - Contains the delimiter, colon, quotes, or control chars
/// - Looks like a boolean, number, or null
/// - Starts with "- " (list marker)
/// - Looks like a structural token ([, {)
bool needsQuoting(String value, String delimiter) {
  if (value.isEmpty) return true;
  if (value.startsWith(' ') || value.endsWith(' ')) return true;
  if (value.contains(delimiter)) return true;
  if (value.contains(':')) return true;
  if (value.contains('"')) return true;
  if (value.contains('\\')) return true;
  if (value.contains('\n') || value.contains('\r') || value.contains('\t'))
    return true;
  if (value.startsWith('- ')) return true;
  if (value == 'true' || value == 'false' || value == 'null') return true;
  if (looksLikeNumber(value)) return true;
  if (RegExp(r'^\[.*\]$').hasMatch(value)) return true;
  if (RegExp(r'^\{.*\}$').hasMatch(value)) return true;

  return false;
}

/// Checks if a string looks like a number.
bool looksLikeNumber(String value) {
  return num.tryParse(value) != null;
}

/// Checks if a string is a valid TOON identifier.
///
/// Valid identifiers:
/// - Start with a letter or underscore
/// - Contain only letters, digits, underscores, or dots
bool isValidIdentifier(String key) {
  if (key.isEmpty) return false;
  if (!RegExp(r'^[a-zA-Z_]').hasMatch(key)) return false;
  return RegExp(r'^[a-zA-Z_][a-zA-Z0-9_.]*$').hasMatch(key);
}

// ============================================================================
// Value Normalization and Parsing
// ============================================================================

/// Normalizes a value for TOON encoding.
///
/// Converts:
/// - NaN/Infinity to null
/// - DateTime to ISO string
/// - Other types pass through unchanged
dynamic normalizeValue(dynamic value) {
  if (value is num) {
    if (value.isNaN || value.isInfinite) return null;
    return value;
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  return value;
}

/// Parses a string value to its appropriate Dart type.
///
/// Handles: null, booleans, numbers, and strings
dynamic parseValue(String value) {
  final trimmed = value.trim();

  if (trimmed.isEmpty) return null;
  if (trimmed == 'null') return null;
  if (trimmed == 'true') return true;
  if (trimmed == 'false') return false;

  // Try number
  final numValue = num.tryParse(trimmed);
  if (numValue != null) return numValue;

  // String (will be unquoted by caller if needed)
  return unquoteString(trimmed);
}

// ============================================================================
// Delimiter Splitting Utilities
// ============================================================================

/// Splits a string by the specified delimiter.
///
/// Handles quoted strings properly (doesn't split inside quotes)
List<String> splitByDelimiter(String value, String delimiter) {
  if (delimiter == ',') {
    return splitByComma(value);
  } else if (delimiter == '\t') {
    return value.split('\t');
  } else if (delimiter == '|') {
    return value.split('|');
  }
  return [value];
}

/// Splits a string by commas, respecting quoted strings.
///
/// Does not split on commas inside quoted strings
List<String> splitByComma(String value) {
  final result = <String>[];
  var current = StringBuffer();
  var inQuotes = false;
  var escapeNext = false;

  for (var i = 0; i < value.length; i++) {
    if (escapeNext) {
      current.write(value[i]);
      escapeNext = false;
      continue;
    }

    if (value[i] == '\\') {
      escapeNext = true;
      current.write(value[i]);
      continue;
    }

    if (value[i] == '"') {
      inQuotes = !inQuotes;
      current.write(value[i]);
      continue;
    }

    if (!inQuotes && value[i] == ',') {
      result.add(current.toString());
      current = StringBuffer();
      continue;
    }

    current.write(value[i]);
  }

  result.add(current.toString());
  return result;
}

// ============================================================================
// Map Flattening Utilities
// ============================================================================

/// Flattens a nested map into a single-level map with compound keys.
///
/// Converts: `{'a': {'b': {'c': 1}}}` to `{'a_b_c': 1}`
Map<String, dynamic> flattenMap(
  Map<String, dynamic> map,
  String separator, [
  String prefix = '',
]) {
  final result = <String, dynamic>{};

  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix$separator${entry.key}';
    final value = entry.value;

    if (value is Map<String, dynamic> && value.isNotEmpty) {
      result.addAll(flattenMap(value, separator, key));
    } else {
      result[key] = value;
    }
  }

  return result;
}

/// Reconstructs a nested map from flattened keys.
///
/// Converts: `{'a_b_c': 1}` to `{'a': {'b': {'c': 1}}}`
Map<String, dynamic> unflattenMap(Map<String, dynamic> flat, String separator) {
  final result = <String, dynamic>{};

  for (final entry in flat.entries) {
    final parts = entry.key.split(separator);
    dynamic current = result;

    for (var i = 0; i < parts.length - 1; i++) {
      current.putIfAbsent(parts[i], () => <String, dynamic>{});
      current = current[parts[i]];
    }

    current[parts.last] = entry.value;
  }

  return result;
}
