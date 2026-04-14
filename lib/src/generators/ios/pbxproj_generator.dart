import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import '../../models/flavor.dart';

class PbxprojGenerator {
  static void applyFlavors(String xcodeProjectPath, List<Flavor> flavors) {
    final pbxprojPath = path.join(xcodeProjectPath, 'project.pbxproj');
    if (!File(pbxprojPath).existsSync()) {
      print('project.pbxproj not found — skipping iOS build configurations.');
      return;
    }

    var content = File(pbxprojPath).readAsStringSync();
    bool changed = false;

    for (final flavor in flavors) {
      if (content.contains('name = Debug-${flavor.name}')) {
        print('iOS config for ${flavor.name} already exists, skipping.');
        continue;
      }
      final updated = _injectBuildConfigurations(content, flavor.name);
      if (updated != content) {
        content = updated;
        changed = true;
        print('iOS build configurations added for ${flavor.name}');
      }
    }

    if (changed) {
      File(pbxprojPath).writeAsStringSync(content);
      print('Open Xcode and verify schemes appear under Product -> Scheme.');
    }
  }

  static void removeFlavor(String xcodeProjectPath, String flavorName) {
    final pbxprojPath = path.join(xcodeProjectPath, 'project.pbxproj');
    if (!File(pbxprojPath).existsSync()) return;

    var content = File(pbxprojPath).readAsStringSync();

    for (final configName in ['Debug-$flavorName', 'Release-$flavorName']) {
      final pattern = RegExp(
        r'\t\t[A-F0-9]{24} /\* ' + configName + r' \*/ = \{[\s\S]*?name = ' + configName + r';[\s\S]*?\};\n',
      );
      content = content.replaceFirst(pattern, '');
    }

    File(pbxprojPath).writeAsStringSync(content);
    print('iOS build configurations removed for $flavorName');
  }

  static String _injectBuildConfigurations(String content, String flavorName) {
    final debugEntry = _extractConfigEntry(content, 'Debug');
    final releaseEntry = _extractConfigEntry(content, 'Release');

    if (debugEntry == null || releaseEntry == null) {
      print('Could not find base Debug/Release configs — skipping iOS for $flavorName');
      return content;
    }

    final debugUuid = _uuid();
    final releaseUuid = _uuid();

    final newDebug = debugEntry
        .replaceFirst(RegExp(r'[A-F0-9]{24} /\* Debug \*/'), '$debugUuid /* Debug-$flavorName */')
        .replaceFirst('name = Debug;', 'name = Debug-$flavorName;');

    final newRelease = releaseEntry
        .replaceFirst(RegExp(r'[A-F0-9]{24} /\* Release \*/'), '$releaseUuid /* Release-$flavorName */')
        .replaceFirst('name = Release;', 'name = Release-$flavorName;');

    const endMarker = '/* End XCBuildConfiguration section */';
    return content.replaceFirst(endMarker, '$newDebug\n$newRelease\n\t\t$endMarker');
  }

  static String? _extractConfigEntry(String content, String name) {
    final pattern = RegExp(
      r'\t\t[A-F0-9]{24} /\* ' + name + r' \*/ = \{[\s\S]*?name = ' + name + r';[\s\S]*?\};',
    );
    return pattern.firstMatch(content)?.group(0);
  }

  static String _uuid() {
    final r = Random.secure();
    return List.generate(24, (_) => r.nextInt(16).toRadixString(16).toUpperCase()).join();
  }
}