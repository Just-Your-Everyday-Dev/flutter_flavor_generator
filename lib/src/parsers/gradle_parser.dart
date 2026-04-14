class GradleParser {
  static ({int start, int end})? findBlock(String content, String blockName, {int startFrom = 0}) {
    int startIdx = -1;
    for (final pattern in ['$blockName {', '$blockName{']) {
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
    return RegExp(r'^\s{4,8}(\w+)\s*\{', multiLine: true)
        .allMatches(productFlavorsBlock)
        .map((m) => m.group(1)!)
        .where((n) => !_reserved.contains(n))
        .toList();
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
  };
}