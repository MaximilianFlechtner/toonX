## 1.2.0

-   Added XML support with `xmlToToon()` and `toonToXml()` functions
-   XML conversion powered by the xml2json package
-   Support for Parker convention (lightweight, ideal for LLMs)
-   Support for Badgerfish convention (preserves attributes and namespaces)
-   CLI now supports XML files (.xml) with auto-detection
-   Added 26 comprehensive tests for XML conversion
-   Updated README with XML examples and proper credits
-   Total test count: 105+ tests

## 1.1.0

-   Added YAML support with `yamlToToon()` and `toonToYaml()` functions
-   CLI now supports YAML files (.yaml, .yml) with auto-detection
-   Added 33 comprehensive tests for YAML conversion
-   Updated README with YAML examples and usage guide
-   Total test count: 79+ tests

## 1.0.1

-   Fixed LICENSE file to comply with pub.dev requirements
-   Reduced topics to 5 for pub.dev compliance
-   Updated README with Credits & Reference section
-   Added comprehensive contribution guidelines
-   Minor documentation improvements

## 1.0.0

-   Initial release
-   `encode()` function to convert Dart objects to TOON format
-   `decode()` function to parse TOON strings back to Dart objects
-   Custom delimiters support: comma, tab, and pipe
-   Length marker option for array validation
-   Custom indentation configuration
-   Tabular array format for uniform objects
-   Flat map mode for flattening nested structures
-   Strict mode validation for decoding
-   Lenient mode for best-effort parsing
-   CLI tool for encoding and decoding files
-   Stdin/stdout support for piping
-   Auto-detection of format by file extension
