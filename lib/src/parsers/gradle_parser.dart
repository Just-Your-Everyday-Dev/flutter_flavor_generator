class GradleParser {
  static ({int start, int end})? findBlock(String content, String blockName, {int startFrom = 0}) {
    // Support both Kotlin DSL create("name") { and Groovy DSL name {
    final patterns = [
      'create("$blockName") {',
      'create("$blockName"){',
      '$blockName {',
      '$blockName{',
    ];

    int startIdx = -1;
    for (final pattern in patterns) {
      startIdx = content.indexOf(pattern, startFrom);
      if (startIdx != -1) break;
    }
    if (startIdx == -1) return null;

    int depth = 0, i = startIdx;
    while (i < content.length) {
      if (content[i] == '{') depth++;
      if (content[i] == '}') {
        depth--;
        if (depth == 0) return (start: startIdx, end: i + 1);
      }
      i++;
    }
    return null;
  }

  static List<String> extractFlavorNames(String productFlavorsBlock) {
    final names = <String>[];

    // Kotlin DSL: create("flavorName") {
    for (final m in RegExp(r'create\("(\w+)"\)\s*\{', multiLine: true).allMatches(productFlavorsBlock)) {
      final name = m.group(1)!;
      if (!_reserved.contains(name)) names.add(name);
    }

    // Groovy DSL: flavorName {  (only if not already found via KTS)
    if (names.isEmpty) {
      for (final m in RegExp(r'^\s{4,8}(\w+)\s*\{', multiLine: true).allMatches(productFlavorsBlock)) {
        final name = m.group(1)!;
        if (!_reserved.contains(name)) names.add(name);
      }
    }

    return names;
  }

  static bool hasFlavorDimensions(String content) =>
      content.contains('flavorDimensions');

  static const _reserved = {
    'dimension',
    'applicationId',
    'resValue',
    'buildConfigField',
    'versionCode',
    'versionName',
    'minSdk',
    'targetSdk',
    'create',
  };
}