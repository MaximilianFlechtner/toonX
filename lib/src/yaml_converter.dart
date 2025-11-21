import 'package:yaml/yaml.dart';
import 'encode.dart';
import 'decode.dart';
import 'options.dart';

/// Converts a YAML string to TOON format.
///
/// Takes a YAML-formatted string and converts it to TOON format through
/// an intermediate Dart object representation.
///
/// [yamlString]: The YAML string to convert.
/// [options]: Optional encoding options for customizing the TOON output.
///
/// Returns a TOON-formatted string.
///
/// Throws [FormatException] if the YAML string is invalid.
String yamlToToon(String yamlString, {EncodeOptions options = const EncodeOptions()}) {
  try {
    final yamlData = loadYaml(yamlString);
    final data = _convertYamlNode(yamlData);
    return encode(data, options: options);
  } catch (e) {
    throw FormatException('Invalid YAML: $e');
  }
}

/// Converts a TOON string to YAML format.
///
/// Takes a TOON-formatted string and converts it to YAML format through
/// an intermediate Dart object representation.
///
/// [toonString]: The TOON string to convert.
/// [options]: Optional decoding options for parsing the TOON input.
///
/// Returns a YAML-formatted string.
///
/// Throws [ToonException] if the TOON string is invalid.
/// Throws [FormatException] if the conversion to YAML fails.
String toonToYaml(String toonString, {DecodeOptions options = const DecodeOptions()}) {
  final data = decode(toonString, options: options);
  return _convertToYaml(data);
}

/// Converts a YamlNode to a standard Dart object.
///
/// Recursively processes YAML nodes and converts them to their
/// Dart equivalents (Map, List, or primitive types).
dynamic _convertYamlNode(dynamic node) {
  if (node is YamlMap) {
    final map = <String, dynamic>{};
    node.forEach((key, value) {
      map[key.toString()] = _convertYamlNode(value);
    });
    return map;
  } else if (node is YamlList) {
    return node.map((item) => _convertYamlNode(item)).toList();
  } else {
    // Primitive types (String, num, bool, null)
    return node;
  }
}

/// Converts a Dart object to YAML string format.
///
/// Recursively processes Dart objects and generates a properly
/// formatted YAML string with appropriate indentation.
String _convertToYaml(dynamic data, {int indent = 0}) {
  final buffer = StringBuffer();
  final indentStr = '  ' * indent;

  if (data is Map<String, dynamic>) {
    if (indent == 0 && data.isEmpty) {
      return '{}\n';
    }
    data.forEach((key, value) {
      if (value is Map && value.isNotEmpty) {
        buffer.write('$indentStr$key:\n');
        buffer.write(_convertToYaml(value, indent: indent + 1));
      } else if (value is List && value.isNotEmpty) {
        buffer.write('$indentStr$key:\n');
        buffer.write(_convertToYaml(value, indent: indent + 1));
      } else if (value == null) {
        buffer.write('$indentStr$key: null\n');
      } else if (value is String) {
        if (_needsYamlQuoting(value)) {
          buffer.write('$indentStr$key: "${_escapeYamlString(value)}"\n');
        } else {
          buffer.write('$indentStr$key: $value\n');
        }
      } else if (value is Map && value.isEmpty) {
        buffer.write('$indentStr$key: {}\n');
      } else if (value is List && value.isEmpty) {
        buffer.write('$indentStr$key: []\n');
      } else {
        buffer.write('$indentStr$key: $value\n');
      }
    });
  } else if (data is List) {
    for (var item in data) {
      if (item is Map || item is List) {
        buffer.write('$indentStr-\n');
        final itemYaml = _convertToYaml(item, indent: indent + 1);
        // Remove first indentation as '-' already provides spacing
        final lines = itemYaml.split('\n');
        for (var line in lines) {
          if (line.isNotEmpty) {
            buffer.write('$indentStr  ${line.trimLeft()}\n');
          }
        }
      } else if (item is String) {
        if (_needsYamlQuoting(item)) {
          buffer.write('$indentStr- "${_escapeYamlString(item)}"\n');
        } else {
          buffer.write('$indentStr- $item\n');
        }
      } else if (item == null) {
        buffer.write('$indentStr- null\n');
      } else {
        buffer.write('$indentStr- $item\n');
      }
    }
  } else {
    // Primitive at root level
    if (data is String) {
      if (_needsYamlQuoting(data)) {
        buffer.write('"${_escapeYamlString(data)}"\n');
      } else {
        buffer.write('$data\n');
      }
    } else {
      buffer.write('$data\n');
    }
  }

  return buffer.toString();
}

/// Determines if a string value needs quoting in YAML.
///
/// Returns true if the string contains special characters or
/// could be misinterpreted as a YAML scalar type.
bool _needsYamlQuoting(String value) {
  if (value.isEmpty) return true;
  if (value.contains('\n') || value.contains('\t')) return true;
  if (value.contains(':') || value.contains('#')) return true;
  if (value.contains('"') || value.contains("'")) return true;
  if (value.startsWith(' ') || value.endsWith(' ')) return true;
  if (value == 'true' || value == 'false') return false; // Let YAML handle booleans
  if (value == 'null') return true; // Quote the string "null"
  if (value.startsWith('[') || value.startsWith('{')) return true;
  if (value.startsWith('-') && value.length > 1 && value[1] == ' ') return true;
  return false;
}

/// Escapes special characters in a string for YAML output.
///
/// Handles common escape sequences like newlines, tabs, and quotes.
String _escapeYamlString(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t')
      .replaceAll('\r', '\\r');
}

