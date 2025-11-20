import 'dart:io';
import 'dart:convert';
import 'package:toonx/toonx.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    _printHelp();
    exit(0);
  }

  final command = arguments[0];

  if (command == '--help' || command == '-h') {
    _printHelp();
    exit(0);
  }

  if (command == 'encode') {
    await _encode(arguments.sublist(1));
  } else if (command == 'decode') {
    await _decode(arguments.sublist(1));
  } else if (File(command).existsSync()) {
    await _autoDetect(command);
  } else {
    stderr.writeln('Error: Unknown command or file not found: $command');
    _printHelp();
    exit(1);
  }
}

Future<void> _encode(List<String> args) async {
  try {
    String input;
    
    if (args.isNotEmpty && File(args[0]).existsSync()) {
      input = await File(args[0]).readAsString();
    } else {
      input = await _readStdin();
    }

    final data = jsonDecode(input);
    final toon = encode(data);
    stdout.write(toon);
  } catch (e) {
    stderr.writeln('Error encoding: $e');
    exit(1);
  }
}

Future<void> _decode(List<String> args) async {
  try {
    String input;
    
    if (args.isNotEmpty && File(args[0]).existsSync()) {
      input = await File(args[0]).readAsString();
    } else {
      input = await _readStdin();
    }

    final data = decode(input);
    final json = jsonEncode(data);
    stdout.writeln(json);
  } catch (e) {
    stderr.writeln('Error decoding: $e');
    exit(1);
  }
}

Future<void> _autoDetect(String filePath) async {
  try {
    final file = File(filePath);
    final input = await file.readAsString();
    final trimmed = input.trim();

    if (filePath.endsWith('.toon')) {
      final data = decode(input);
      final json = jsonEncode(data);
      stdout.writeln(json);
    } else if (filePath.endsWith('.json')) {
      final data = jsonDecode(input);
      final toon = encode(data);
      stdout.write(toon);
    } else if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      final data = jsonDecode(input);
      final toon = encode(data);
      stdout.write(toon);
    } else {
      final data = decode(input);
      final json = jsonEncode(data);
      stdout.writeln(json);
    }
  } catch (e) {
    stderr.writeln('Error processing file: $e');
    exit(1);
  }
}

Future<String> _readStdin() async {
  final buffer = StringBuffer();
  await for (final line in stdin.transform(utf8.decoder)) {
    buffer.write(line);
  }
  return buffer.toString();
}

void _printHelp() {
  print('''
toonX - TOON (Token-Oriented Object Notation) CLI

Usage:
  dart run toonx encode [file]     Encode JSON to TOON
  dart run toonx decode [file]     Decode TOON to JSON
  dart run toonx <file>            Auto-detect format and convert
  dart run toonx --help            Show this help message

Examples:
  # Encode from stdin
  echo '{"id": 1, "name": "Alice"}' | dart run toonx encode

  # Decode from file
  dart run toonx decode data.toon

  # Auto-detect by extension
  dart run toonx file.json     # encodes to TOON
  dart run toonx file.toon     # decodes to JSON

Input:
  - Reads from stdin if no file is provided
  - Reads from file if path is provided

Output:
  - Writes to stdout
''');
}

