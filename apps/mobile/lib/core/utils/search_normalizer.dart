/// Arama için metni sadeleştirir: Türkçe büyük/küçük harf farkını ve
/// aksanlı harfleri yok sayar. "İstanbul", "istanbul" ve "ISTANBUL" eşleşir.
abstract final class SearchNormalizer {
  static const Map<String, String> _replacements = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ü': 'u',
    'ü': 'u',
    'Ö': 'o',
    'ö': 'o',
    'Ç': 'c',
    'ç': 'c',
    'Â': 'a',
    'â': 'a',
  };

  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final char in value.trim().split('')) {
      buffer.write(_replacements[char] ?? char.toLowerCase());
    }
    return buffer.toString();
  }

  static bool matches(String text, String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;
    return normalize(text).contains(normalizedQuery);
  }
}
