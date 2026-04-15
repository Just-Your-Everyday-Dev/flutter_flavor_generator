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
      if (updated == content) {
        print('Warning: iOS config injection produced no changes for ${flavor.name} — skipping write.');
        continue;
      }
      content = updated;
      changed = true;
      print('iOS build configurations added for ${flavor.name}');
    }

    if (changed) {
      File(pbxprojPath).writeAsStringSync(content);
      print('Open Xcode and verify schemes appear under Product -> Scheme.');
    }
  }

  static void removeFlavor(String xcodeProjectPath, String flavorName) {
    final pbxprojPath = path.join(xcodeProjectPath, 'project.pbxproj');
    if (!File(pbxprojPath).existsSync()) return;

    final content = _removeFlavorFromContent(
      File(pbxprojPath).readAsStringSync(),
      flavorName,
    );
    File(pbxprojPath).writeAsStringSync(content);
    print('iOS build configurations removed for $flavorName');
  }

  static String _removeFlavorFromContent(String content, String flavorName) {
    for (final configName in ['Debug-$flavorName', 'Release-$flavorName', 'Profile-$flavorName']) {
      final entryPattern = RegExp(
        r'\t\t[A-F0-9]{24} /\* ' + configName + r' \*/ = \{[\s\S]*?name = ' + configName + r';[\s\S]*?\};\n',
      );
      content = content.replaceAll(entryPattern, '');

      final refPattern = RegExp(r'\t\t\t\t[A-F0-9]{24} /\* ' + configName + r' \*/,\n');
      content = content.replaceAll(refPattern, '');
    }
    return content;
  }

  /// Injects flavor build configurations for every XCConfigurationList entry.
  ///
  /// A Flutter pbxproj has *two* XCConfigurationList sections — one for the
  /// PBXProject and one for the Runner target — each referencing their own
  /// Debug / Release / Profile UUID.  We must create a separate new UUID for
  /// each existing reference so that project-level and target-level settings
  /// (including SWIFT_VERSION) are preserved independently.
  static String _injectBuildConfigurations(String content, String flavorName) {
    var result = content;

    // Detect the Swift version used in this project so we can set it explicitly
    // on every generated config.  CocoaPods only manages SWIFT_VERSION via xcconfig
    // for configurations it recognises (Debug / Release / Profile); for unknown
    // flavor configs it leaves the setting empty, causing a "multiple SWIFT_VERSION"
    // error.  Setting it inline in buildSettings always wins over xcconfig.
    final swiftVersion = _detectSwiftVersion(content);

    for (final baseName in ['Debug', 'Release', 'Profile']) {
      final newName = '$baseName-$flavorName';

      // Find every XCConfigurationList reference of the form:
      //   \t\t\t\t{UUID} /* Debug */,
      final refPattern = RegExp(
        r'(\t\t\t\t([A-F0-9]{24}) /\* ' + baseName + r' \*/,)',
      );
      final refs = refPattern.allMatches(result).toList();

      if (refs.isEmpty) {
        print('No XCConfigurationList reference found for $baseName — skipping iOS for $flavorName');
        return content;
      }

      final newEntries = <String>[];

      for (final ref in refs) {
        final fullRef = ref.group(1)!;
        final originalUuid = ref.group(2)!;
        final newUuid = _uuid();

        // Copy the XCBuildConfiguration entry that owns this UUID
        final entryPattern = RegExp(
          r'\t\t' + originalUuid + r' /\* ' + baseName + r' \*/ = \{[\s\S]*?name = ' + baseName + r';[\s\S]*?\};',
        );
        final entryMatch = entryPattern.firstMatch(result);
        if (entryMatch == null) continue;

        var newEntry = entryMatch.group(0)!
            .replaceFirst('$originalUuid /* $baseName */', '$newUuid /* $newName */')
            .replaceFirst('name = $baseName;', 'name = $newName;');

        // Ensure SWIFT_VERSION is set inline so CocoaPods cannot leave it empty
        // for flavor configurations it does not natively recognise.
        if (swiftVersion != null && !newEntry.contains('SWIFT_VERSION')) {
          newEntry = newEntry.replaceFirst(
            'buildSettings = {',
            'buildSettings = {\n\t\t\t\tSWIFT_VERSION = $swiftVersion;',
          );
        }

        newEntries.add(newEntry);

        // Insert the new UUID reference immediately after the original in the list
        result = result.replaceFirst(
          fullRef,
          '$fullRef\n\t\t\t\t$newUuid /* $newName */,',
        );
      }

      // Append all new XCBuildConfiguration entries before the section end marker
      if (newEntries.isNotEmpty) {
        const endMarker = '/* End XCBuildConfiguration section */';
        result = result.replaceFirst(
          endMarker,
          '${newEntries.join('\n')}\n\t\t$endMarker',
        );
      }
    }

    return result;
  }

  /// Returns the SWIFT_VERSION value found anywhere in [content], or null if
  /// none is set (meaning the project contains no Swift code).
  static String? _detectSwiftVersion(String content) {
    final match = RegExp(r'SWIFT_VERSION\s*=\s*([^;]+);').firstMatch(content);
    return match?.group(1)?.trim();
  }

  static String _uuid() {
    final r = Random.secure();
    return List.generate(24, (_) => r.nextInt(16).toRadixString(16).toUpperCase()).join();
  }
}