/// Arabic search-keyword builder for prefix search with
/// `where('searchKeywords', arrayContains: token)`.
///
/// Stored on each property document and rebuilt on every admin save.
class SearchKeywords {
  SearchKeywords._();

  static const int maxTokens = 60;

  /// Normalizes Arabic text: strips diacritics/tatweel, unifies alef/hamza,
  /// teh-marbuta and alef-maqsura so "شقة" matches "شقه" etc.
  static String normalize(String input) {
    String s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\u064B-\u0652\u0670]'), ''); // diacritics
    s = s.replaceAll('ـ', ''); // tatweel
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  /// Builds prefix tokens: "شقه" -> {ش, شق, شقه}, plus full tokens of every
  /// word so partial typing matches from the first letters.
  static List<String> build({
    required String title,
    required String cityName,
    required String areaName,
    required String typeName,
    String address = '',
    String purpose = '',
  }) {
    final Set<String> tokens = <String>{};
    final List<String> sources = <String>[
      title,
      cityName,
      areaName,
      typeName,
      address,
      purpose,
    ];
    for (final String source in sources) {
      final String normalized = normalize(source);
      if (normalized.isEmpty) continue;
      for (final String word in normalized.split(' ')) {
        final String w = word.trim();
        if (w.length < 2) continue;
        tokens.add(w);
        for (int i = 2; i < w.length; i++) {
          tokens.add(w.substring(0, i));
        }
        if (tokens.length >= maxTokens) break;
      }
      if (tokens.length >= maxTokens) break;
    }
    return tokens.take(maxTokens).toList();
  }

  /// Normalizes a user-typed query into lookup tokens (last word prefix).
  static List<String> queryTokens(String query) {
    final String normalized = normalize(query);
    if (normalized.isEmpty) return const <String>[];
    return normalized
        .split(' ')
        .map((String w) => w.trim())
        .where((String w) => w.length >= 2)
        .toList();
  }
}
