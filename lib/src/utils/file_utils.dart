import 'dart:io';
import 'package:path/path.dart' as path;

class FileUtils {
  static void writeFile(String filePath, String content) {
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    print('Created: $filePath');
  }

  static String? readFile(String filePath) {
    final file = File(filePath);
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  static bool fileExists(String filePath) => File(filePath).existsSync();
  static String resolveLibPath(String root) => path.join(root, 'lib');

  static String? resolveAndroidPath(String root) {
    final gradle = path.join(root, 'android', 'app', 'build.gradle');
    final gradleKts = path.join(root, 'android', 'app', 'build.gradle.kts');
    if (File(gradle).existsSync()) return gradle;
    if (File(gradleKts).existsSync()) return gradleKts;
    return null;
  }

  static String? resolveIosPath(String root) {
    final p = path.join(root, 'ios', 'Runner.xcodeproj');
    return Directory(p).existsSync() ? p : null;
  }
}