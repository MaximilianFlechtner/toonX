/// Configuration options for encoding Dart values to TOON format.
///
/// Provides fine-grained control over TOON encoding behavior including
/// indentation, delimiters, length markers, and flat map support.
class EncodeOptions {
  /// Number of spaces per indentation level.
  ///
  /// Controls how many spaces are used for each nesting level.
  /// Default: `2`
  final int indent;

  /// Delimiter character for array values and tabular rows.
  ///
  /// Available options:
  /// - `','` (comma) - Default, widely supported
  /// - `'\t'` (tab) - Better token efficiency for large datasets
  /// - `'|'` (pipe) - Visual clarity
  ///
  /// Tab delimiters often provide the best token savings for LLMs.
  ///
  /// Default: `','`
  final String delimiter;

  /// Optional marker to prefix array lengths for clarity.
  ///
  /// When set to `'#'`, array lengths are prefixed with `#` to make it
  /// explicit that the number represents a count, not an index.
  ///
  /// - `null` - No marker (default): `items[3]:`
  /// - `'#'` - With marker: `items[#3]:`
  ///
  /// Default: `null`
  final String? lengthMarker;

  /// Whether to flatten nested maps into dot-notation keys.
  ///
  /// When `true`, nested maps are flattened using the [flatMapSeparator].
  /// Input: `{'a': {'b': {'c': 1}}}` becomes `a_b_c: 1`
  ///
  /// Default: `false`
  final bool enforceFlatMap;

  /// Separator character for flattened map keys.
  ///
  /// Used when [enforceFlatMap] is `true` to join nested keys.
  ///
  /// Common separators:
  /// - `'_'` (underscore) - Default, safe for most uses
  /// - `'.'` (dot) - Common in configuration files
  /// - `':'` (colon) - Alternative notation
  ///
  /// Default: `'_'`
  final String flatMapSeparator;

  /// Creates encoding options with the specified configuration.
  ///
  /// All parameters are optional and have sensible defaults.
  const EncodeOptions({
    this.indent = 2,
    this.delimiter = ',',
    this.lengthMarker,
    this.enforceFlatMap = false,
    this.flatMapSeparator = '_',
  });

  /// Returns the delimiter marker string for array headers.
  ///
  /// - Comma delimiter returns empty string (implicit)
  /// - Tab and pipe delimiters return themselves (explicit)
  String get delimiterMarker {
    if (delimiter == ',') return '';
    if (delimiter == '\t') return '\t';
    if (delimiter == '|') return '|';
    return '';
  }
}

/// Configuration options for decoding TOON format to Dart values.
///
/// Provides control over validation strictness, indentation expectations,
/// and flat map reconstruction.
class DecodeOptions {
  /// Expected number of spaces per indentation level.
  ///
  /// Must match the indentation used during encoding. Used to determine
  /// the nesting level of each line.
  ///
  /// Default: `2`
  final int indent;

  /// Enable strict validation during decoding.
  ///
  /// When `true` (default):
  /// - Validates array lengths match declared counts
  /// - Ensures delimiters are consistent
  /// - Throws [ToonException] on validation failures
  /// - Validates escape sequences
  ///
  /// When `false` (lenient mode):
  /// - Tolerates array length mismatches
  /// - Attempts to parse even with errors
  /// - Returns partial results when possible
  ///
  /// Default: `true`
  final bool strict;

  /// Whether to reconstruct nested maps from flattened keys.
  ///
  /// When `true`, keys containing [flatMapSeparator] are split and
  /// reconstructed into nested map structures.
  /// Input: `"a_b_c: 1"` becomes `{'a': {'b': {'c': 1}}}`
  ///
  /// Default: `false`
  final bool enforceFlatMap;

  /// Separator character used in flattened map keys.
  ///
  /// Must match the separator used during encoding with [EncodeOptions.flatMapSeparator].
  ///
  /// Default: `'_'`
  final String flatMapSeparator;

  /// Creates decoding options with the specified configuration.
  ///
  /// All parameters are optional and have sensible defaults.
  const DecodeOptions({
    this.indent = 2,
    this.strict = true,
    this.enforceFlatMap = false,
    this.flatMapSeparator = '_',
  });
}

