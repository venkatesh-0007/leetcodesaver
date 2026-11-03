class SupportedLanguage {
  final String name;
  final String code; // for LeetCode slug e.g. 'python3', 'cpp', 'java'
  final String extension;
  final String highlightLanguage; // for flutter_highlight

  const SupportedLanguage({
    required this.name,
    required this.code,
    required this.extension,
    required this.highlightLanguage,
  });

  static const List<SupportedLanguage> all = [
    SupportedLanguage(name: 'Python 3', code: 'python3', extension: '.py', highlightLanguage: 'python'),
    SupportedLanguage(name: 'C++', code: 'cpp', extension: '.cpp', highlightLanguage: 'cpp'),
    SupportedLanguage(name: 'Java', code: 'java', extension: '.java', highlightLanguage: 'java'),
    SupportedLanguage(name: 'JavaScript', code: 'javascript', extension: '.js', highlightLanguage: 'javascript'),
    SupportedLanguage(name: 'TypeScript', code: 'typescript', extension: '.ts', highlightLanguage: 'typescript'),
    SupportedLanguage(name: 'Go', code: 'golang', extension: '.go', highlightLanguage: 'go'),
    SupportedLanguage(name: 'Rust', code: 'rust', extension: '.rs', highlightLanguage: 'rust'),
    SupportedLanguage(name: 'Kotlin', code: 'kotlin', extension: '.kt', highlightLanguage: 'kotlin'),
    SupportedLanguage(name: 'C', code: 'c', extension: '.c', highlightLanguage: 'c'),
    SupportedLanguage(name: 'C#', code: 'csharp', extension: '.cs', highlightLanguage: 'cs'),
    SupportedLanguage(name: 'Swift', code: 'swift', extension: '.swift', highlightLanguage: 'swift'),
  ];

  static SupportedLanguage fromExtension(String ext) {
    final cleanExt = ext.startsWith('.') ? ext.toLowerCase() : '.$ext'.toLowerCase();
    for (final lang in all) {
      if (lang.extension.toLowerCase() == cleanExt) return lang;
    }
    return all.first; // Default to Python 3
  }

  static SupportedLanguage fromName(String name) {
    for (final lang in all) {
      if (lang.name.toLowerCase() == name.toLowerCase() ||
          lang.code.toLowerCase() == name.toLowerCase()) {
        return lang;
      }
    }
    return all.first;
  }
}

