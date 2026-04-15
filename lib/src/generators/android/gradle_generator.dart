import 'dart:io';
import '../../models/flavor.dart';
import '../../parsers/gradle_parser.dart';

class GradleGenerator {
  static void applyFlavors(String gradlePath, List<Flavor> flavors) {
    if (!File(gradlePath).existsSync()) {
      print(' build.gradle not found at $gradlePath — skipping Android.');
      return;
    }

    final isKts = gradlePath.endsWith('.kts');
    var content = File(gradlePath).readAsStringSync();
    final existingBlock = GradleParser.findBlock(content, 'productFlavors');

    if (existingBlock == null) {
      final androidBlock = GradleParser.findBlock(content, 'android');
      if (androidBlock == null) {
        print('No android { } block found in build.gradle — skipping.');
        return;
      }
      final injection = _buildFullBlock(flavors, isKts: isKts);
      content = '${content.substring(0, androidBlock.end - 1)}\n$injection\n${content.substring(androidBlock.end - 1)}';
    } else {
      final blockContent = content.substring(existingBlock.start, existingBlock.end);
      final existing = GradleParser.extractFlavorNames(blockContent).toSet();
      final toAdd = flavors.where((f) => !existing.contains(f.name)).toList();

      if (toAdd.isEmpty) {
        print('build.gradle already up to date.');
        return;
      }

      final newEntries = toAdd.map((f) => _buildFlavorEntry(f, isKts: isKts)).join('\n');
      content = '${content.substring(0, existingBlock.end - 1)}\n$newEntries${content.substring(existingBlock.end - 1)}';
    }

    File(gradlePath).writeAsStringSync(content);
    print('android/app/build.gradle updated');
  }

  static String _buildFullBlock(List<Flavor> flavors, {required bool isKts}) {
    final entries = flavors.map((f) => _buildFlavorEntry(f, isKts: isKts)).join('\n');
    if (isKts) {
      return '    flavorDimensions += listOf("app")\n\n    productFlavors {\n$entries\n    }';
    }
    return '    flavorDimensions "app"\n\n    productFlavors {\n$entries\n    }';
  }

  static String _buildFlavorEntry(Flavor flavor, {required bool isKts}) {
    final appName = _getAppName(flavor);
    if (isKts) {
      final suffix = flavor.name == 'prod'
          ? ''
          : '            applicationIdSuffix = ".${flavor.name}"\n';
      return '        create("${flavor.name}") {\n'
          '            dimension = "app"\n'
          '$suffix'
          '            resValue("string", "app_name", "$appName")\n'
          '        }';
    }
    final suffix = flavor.name == 'prod'
        ? ''
        : '            applicationIdSuffix ".${flavor.name}"\n';
    return '        ${flavor.name} {\n'
        '            dimension "app"\n'
        '$suffix'
        '            resValue "string", "app_name", "$appName"\n'
        '        }';
  }

  static void removeFlavor(String gradlePath, String flavorName, {required bool isLast}) {
    if (!File(gradlePath).existsSync()) return;

    var content = File(gradlePath).readAsStringSync();

    if (isLast) {
      content = content.replaceAll(RegExp(r'\n[ \t]*flavorDimensions[^\n]*'), '');
      final block = GradleParser.findBlock(content, 'productFlavors');
      if (block != null) {
        content = '${content.substring(0, block.start).trimRight()}\n${content.substring(block.end).trimLeft()}';
      }
    } else {
      final productFlavorsBlock = GradleParser.findBlock(content, 'productFlavors');
      if (productFlavorsBlock != null) {
        final flavorBlock = GradleParser.findBlock(
          content,
          flavorName,
          startFrom: productFlavorsBlock.start,
        );
        if (flavorBlock != null) {
          content = '${content.substring(0, flavorBlock.start).trimRight()}\n${content.substring(flavorBlock.end).trimLeft()}';
        }
      }
    }

    File(gradlePath).writeAsStringSync(content);
    print('android/app/build.gradle updated');
  }

  static String _getAppName(Flavor flavor) {
    try {
      return flavor.parameters.firstWhere((p) => p.name == 'appName').value;
    } catch (_) {
      return flavor.name;
    }
  }
}
