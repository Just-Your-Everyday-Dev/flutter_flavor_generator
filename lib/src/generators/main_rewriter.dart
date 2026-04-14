import 'dart:io';

class MainRewriter {
  static bool revertToMain(String libPath) {
    final commonFile = File('$libPath/main_common.dart');
    if (!commonFile.existsSync()) {
      print('main_common.dart not found — skipping revert.');
      return false;
    }
    final content = commonFile
        .readAsStringSync()
        .replaceAll('void mainCommon()', 'void main()')
        .replaceAll('Future<void> mainCommon()', 'Future<void> main()');
    File('$libPath/main.dart').writeAsStringSync(content);
    commonFile.deleteSync();
    print('main_common.dart -> main.dart');
    return true;
  }

  static void updateWidgetTestImport(String testFilePath) {
    final file = File(testFilePath);
    if (!file.existsSync()) return;
    final original = file.readAsStringSync();
    final updated = original.replaceFirstMapped(
      RegExp(r'(package:[^/]+/)main\.dart'),
      (m) => '${m.group(1)}main_common.dart',
    );
    if (updated != original) {
      file.writeAsStringSync(updated);
      print('test/widget_test.dart updated to main_common.dart');
    }
  }

  static void revertWidgetTestImport(String testFilePath) {
    final file = File(testFilePath);
    if (!file.existsSync()) return;
    final original = file.readAsStringSync();
    final updated = original.replaceFirstMapped(
      RegExp(r'(package:[^/]+/)main_\w+\.dart'),
      (m) => '${m.group(1)}main.dart',
    );
    if (updated != original) {
      file.writeAsStringSync(updated);
      print('test/widget_test.dart reverted to main.dart');
    }
  }

  static bool rewrite(String mainFilePath) {
    final file = File(mainFilePath);
    if (!file.existsSync()) {
      print('No main.dart found — skipping rename.');
      return false;
    }
    final original = file.readAsStringSync();
    final updated = original
        .replaceAll('void main()', 'void mainCommon()')
        .replaceAll('Future<void> main()', 'Future<void> mainCommon()');
    if (updated == original) {
      print('No main() signature found — skipping rename.');
      return false;
    }
    File('${file.parent.path}/main_common.dart').writeAsStringSync(updated);
    file.deleteSync();
    print('  ✅ main.dart → main_common.dart, main() → mainCommon()');
    return true;
  }
}