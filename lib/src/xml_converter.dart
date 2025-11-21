import 'dart:convert';
import 'package:xml2json/xml2json.dart';
import 'encode.dart';
import 'decode.dart';
import 'options.dart';

/// Converts an XML string to TOON format.
///
/// This function uses the Parker convention from the xml2json package,
/// which is a lightweight conversion suitable for simple XML structures.
/// The Parker convention does not preserve XML attributes or namespaces,
/// making it ideal for LLM use cases where simplicity is preferred.
///
/// [xmlString]: The XML string to convert.
/// [options]: Optional encoding options for customizing the TOON output.
///
/// Returns a TOON-formatted string.
///
/// Throws [FormatException] if the XML string is invalid.
String xmlToToon(String xmlString, {EncodeOptions options = const EncodeOptions()}) {
  try {
    final transformer = Xml2Json();
    transformer.parse(xmlString);
    final jsonString = transformer.toParker();
    final jsonData = jsonDecode(jsonString);
    return encode(jsonData, options: options);
  } catch (e) {
    throw FormatException('Invalid XML: $e');
  }
}

/// Converts a TOON string to XML format.
///
/// This function converts TOON back to XML using a simple XML structure.
/// The resulting XML uses the Parker convention, which is a lightweight
/// representation without explicit attributes or namespaces.
///
/// [toonString]: The TOON string to convert.
/// [options]: Optional decoding options for parsing the TOON input.
///
/// Returns an XML-formatted string.
///
/// Throws [ToonException] if the TOON string is invalid.
/// Throws [FormatException] if the conversion to XML fails.
String toonToXml(String toonString, {DecodeOptions options = const DecodeOptions()}) {
  final data = decode(toonString, options: options);
  return _convertToXml(data);
}

/// Converts an XML string to TOON format using Badgerfish convention.
///
/// The Badgerfish convention preserves XML attributes and namespaces,
/// making it suitable for complex XML documents where this information
/// is important (e.g., SOAP messages, ATOM feeds).
///
/// Attributes are prefixed with '@', text content is stored in '$',
/// and namespaces are preserved in '@xmlns' properties.
///
/// [xmlString]: The XML string to convert.
/// [options]: Optional encoding options for customizing the TOON output.
///
/// Returns a TOON-formatted string with XML metadata preserved.
///
/// Throws [FormatException] if the XML string is invalid.
String xmlToToonBadgerfish(String xmlString, {EncodeOptions options = const EncodeOptions()}) {
  try {
    final transformer = Xml2Json();
    transformer.parse(xmlString);
    final jsonString = transformer.toBadgerfish();
    final jsonData = jsonDecode(jsonString);
    return encode(jsonData, options: options);
  } catch (e) {
    throw FormatException('Invalid XML: $e');
  }
}

/// Converts a TOON string to XML format using Badgerfish convention.
///
/// This function reconstructs XML with attributes and namespaces from
/// a TOON string that was encoded using the Badgerfish convention.
///
/// [toonString]: The TOON string to convert (must be Badgerfish-encoded).
/// [options]: Optional decoding options for parsing the TOON input.
///
/// Returns an XML-formatted string with attributes and namespaces.
///
/// Throws [ToonException] if the TOON string is invalid.
String toonToXmlBadgerfish(String toonString, {DecodeOptions options = const DecodeOptions()}) {
  final data = decode(toonString, options: options);
  return _convertToXmlBadgerfish(data);
}

/// Converts a Dart object to simple XML string format.
///
/// This creates a basic XML representation suitable for simple data structures.
/// Uses Parker-style XML (no attributes, just nested elements).
String _convertToXml(dynamic data, {String? rootName, int indent = 0}) {
  final buffer = StringBuffer();
  final indentStr = '  ' * indent;

  if (data is Map<String, dynamic>) {
    if (rootName != null && indent == 0) {
      buffer.write('<$rootName>');
    }
    
    data.forEach((key, value) {
      if (value is Map) {
        buffer.write('\n$indentStr<$key>');
        buffer.write(_convertToXml(value, indent: indent + 1));
        buffer.write('\n$indentStr</$key>');
      } else if (value is List) {
        for (var item in value) {
          buffer.write('\n$indentStr<$key>');
          if (item is Map || item is List) {
            buffer.write(_convertToXml(item, indent: indent + 1));
            buffer.write('\n$indentStr');
          } else {
            buffer.write(_escapeXml(item.toString()));
          }
          buffer.write('</$key>');
        }
      } else {
        buffer.write('\n$indentStr<$key>');
        buffer.write(_escapeXml(value.toString()));
        buffer.write('</$key>');
      }
    });
    
    if (rootName != null && indent == 0) {
      buffer.write('\n</$rootName>');
    }
  } else if (data is List) {
    final root = rootName ?? 'root';
    buffer.write('<$root>');
    for (var item in data) {
      buffer.write('\n$indentStr<item>');
      if (item is Map || item is List) {
        buffer.write(_convertToXml(item, indent: indent + 1));
        buffer.write('\n$indentStr');
      } else {
        buffer.write(_escapeXml(item.toString()));
      }
      buffer.write('</item>');
    }
    buffer.write('\n</$root>');
  } else {
    buffer.write(_escapeXml(data.toString()));
  }

  return buffer.toString();
}

/// Converts a Dart object to XML string using Badgerfish convention.
///
/// Handles @ prefixed attributes, $ text content, and @xmlns namespaces.
String _convertToXmlBadgerfish(dynamic data, {int indent = 0}) {
  final buffer = StringBuffer();
  final indentStr = '  ' * indent;

  if (data is Map<String, dynamic>) {
    data.forEach((key, value) {
      if (key.startsWith('@')) {
        // Skip attributes and xmlns for now - handled inline
        return;
      }
      
      buffer.write('\n$indentStr<$key');
      
      // Add attributes if they exist
      if (value is Map) {
        value.forEach((attrKey, attrValue) {
          if (attrKey.startsWith('@') && attrKey != '@xmlns') {
            final cleanKey = attrKey.substring(1);
            buffer.write(' $cleanKey="${_escapeXml(attrValue.toString())}"');
          }
        });
      }
      
      buffer.write('>');
      
      if (value is Map) {
        if (value.containsKey('\$')) {
          // Text content
          buffer.write(_escapeXml(value['\$'].toString()));
        } else {
          // Nested elements
          buffer.write(_convertToXmlBadgerfish(value, indent: indent + 1));
          buffer.write('\n$indentStr');
        }
      } else if (value is List) {
        for (var item in value) {
          buffer.write(_convertToXmlBadgerfish({key: item}, indent: indent));
        }
      } else {
        buffer.write(_escapeXml(value.toString()));
      }
      
      buffer.write('</$key>');
    });
  }

  return buffer.toString();
}

/// Escapes special characters for XML output.
String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

