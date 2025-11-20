/// Type alias for JSON-compatible values.
///
/// Represents any value that can be encoded to or decoded from TOON format.
/// This includes:
/// - Primitive types: `String`, `num`, `bool`, `null`
/// - Collections: `List<dynamic>`, `Map<String, dynamic>`
/// - Nested combinations of the above
typedef JsonValue = dynamic;
