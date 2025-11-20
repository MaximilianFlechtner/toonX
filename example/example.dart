import 'package:toonx/toonx.dart';

void main() {
  print('=== TOON Format Examples ===\n');

  // Example 1: Basic encoding - JSON to TOON
  basicEncoding();

  // Example 2: Decoding - TOON back to Dart objects
  basicDecoding();

  // Example 3: Tabular arrays for uniform data (CSV-style)
  tabularArrays();

  // Example 4: Custom delimiters for token efficiency
  customDelimiters();

  // Example 5: Length markers for explicit array sizes
  lengthMarkers();

  // Example 6: Flat map for deeply nested structures
  flatMapExample();

  // Example 7: Strict vs lenient parsing modes
  strictVsLenient();

  // Example 8: Real-world use case - E-commerce data
  realWorldExample();
}

/// Basic encoding: Convert Dart objects to TOON format
void basicEncoding() {
  print('1. Basic Encoding\n');

  final data = {
    'name': 'Alice',
    'age': 30,
    'active': true,
    'tags': ['admin', 'developer', 'ops'],
  };

  final toon = encode(data);
  print(toon);
  // Output:
  // name: Alice
  // age: 30
  // active: true
  // tags[3]: admin,developer,ops

  print('\n---\n');
}

/// Decoding: Parse TOON strings back to Dart objects
void basicDecoding() {
  print('2. Basic Decoding\n');

  final toonString = '''
name: Bob
role: engineer
skills[2]: Flutter,Dart
''';

  final decoded = decode(toonString);
  print(decoded);
  // Output: {name: Bob, role: engineer, skills: [Flutter, Dart]}

  print('\n---\n');
}

/// Tabular arrays: Efficient format for uniform data
void tabularArrays() {
  print('3. Tabular Arrays (CSV-style)\n');

  final users = {
    'users': [
      {'id': 1, 'name': 'Alice', 'role': 'admin', 'active': true},
      {'id': 2, 'name': 'Bob', 'role': 'user', 'active': false},
      {'id': 3, 'name': 'Charlie', 'role': 'moderator', 'active': true},
    ],
  };

  final toon = encode(users);
  print(toon);
  // Output:
  // users[3]{id,name,role,active}:
  //   1,Alice,admin,true
  //   2,Bob,user,false
  //   3,Charlie,moderator,true

  print('\n---\n');
}

/// Custom delimiters: Tab or pipe for maximum token efficiency
void customDelimiters() {
  print('4. Custom Delimiters\n');

  final data = {
    'products': [
      {'sku': 'A1', 'price': 29.99, 'stock': 100},
      {'sku': 'B2', 'price': 49.99, 'stock': 50},
    ],
  };

  // Tab delimiter - best for LLM token efficiency
  final withTab = encode(data, options: EncodeOptions(delimiter: '\t'));
  print('Tab delimiter:\n$withTab');

  // Pipe delimiter - human-readable alternative
  final withPipe = encode(data, options: EncodeOptions(delimiter: '|'));
  print('\nPipe delimiter:\n$withPipe');

  print('\n---\n');
}

/// Length markers: Explicit array size validation
void lengthMarkers() {
  print('5. Length Markers\n');

  final data = {
    'items': ['apple', 'banana', 'cherry'],
  };

  final withMarker = encode(data, options: EncodeOptions(lengthMarker: '#'));
  print(withMarker);
  // Output: items[#3]: apple,banana,cherry

  print('\n---\n');
}

/// Flat map: Flatten deeply nested structures
void flatMapExample() {
  print('6. Flat Map (Nested Structure Flattening)\n');

  final config = {
    'database': {
      'connection': {'host': 'localhost', 'port': 5432, 'timeout': 30},
      'pool': {'min': 5, 'max': 20},
    },
  };

  // Flatten with custom separator
  final flattened = encode(
    config,
    options: EncodeOptions(enforceFlatMap: true, flatMapSeparator: '.'),
  );
  print('Flattened:\n$flattened');

  // Unflatten on decode
  final restored = decode(
    flattened,
    options: DecodeOptions(enforceFlatMap: true, flatMapSeparator: '.'),
  );
  print('\nRestored:\n$restored');

  print('\n---\n');
}

/// Strict vs lenient parsing modes
void strictVsLenient() {
  print('7. Strict vs Lenient Parsing\n');

  // Invalid TOON: array declares 3 items but has only 2
  final invalidToon = 'tags[3]: admin,ops';

  // Strict mode (default) - throws exception
  try {
    decode(invalidToon, options: DecodeOptions(strict: true));
  } on ToonException catch (e) {
    print('Strict mode error: ${e.message}');
  }

  // Lenient mode - parses anyway
  final lenient = decode(invalidToon, options: DecodeOptions(strict: false));
  print('Lenient mode result: $lenient');

  print('\n---\n');
}

/// Real-world example: E-commerce order data
void realWorldExample() {
  print('8. Real-World Example: E-commerce Order\n');

  final order = {
    'orderId': 'ORD-2024-001',
    'customer': {
      'name': 'Jane Doe',
      'email': 'jane@example.com',
      'tier': 'premium',
    },
    'items': [
      {'sku': 'LAPTOP-X1', 'qty': 1, 'price': 1299.99},
      {'sku': 'MOUSE-M2', 'qty': 2, 'price': 29.99},
      {'sku': 'USB-C-CABLE', 'qty': 3, 'price': 12.99},
    ],
    'status': 'shipped',
    'total': 1398.94,
  };

  // Encode with tab delimiter for best token efficiency
  final toon = encode(order, options: EncodeOptions(delimiter: '\t'));
  print(toon);

  print(
    '\n✓ TOON uses ~40% fewer tokens than JSON for structured data like this!',
  );

  print('\n---\n');
}
