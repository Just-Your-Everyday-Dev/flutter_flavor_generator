import 'dart:io';
import 'package:path/path.dart' as path;

class XcschemeGenerator {
  static void generate(String xcodeProjectPath, String flavorName) {
    final schemesDir = path.join(xcodeProjectPath, 'xcshareddata', 'xcschemes');
    final schemeFile = File(path.join(schemesDir, '$flavorName.xcscheme'));

    if (schemeFile.existsSync()) {
      print('iOS scheme for $flavorName already exists, skipping.');
      return;
    }

    final runnerScheme = File(path.join(schemesDir, 'Runner.xcscheme'));
    if (!runnerScheme.existsSync()) {
      print('Runner.xcscheme not found, cannot generate $flavorName.xcscheme.');
      return;
    }

    var content = runnerScheme.readAsStringSync();

    content = content.replaceAll('buildConfiguration="Debug"', 'buildConfiguration="Debug-$flavorName"');
    content = content.replaceAll('buildConfiguration="Release"', 'buildConfiguration="Release-$flavorName"');
    content = content.replaceAll('buildConfiguration="Profile"', 'buildConfiguration="Profile-$flavorName"');

    Directory(schemesDir).createSync(recursive: true);
    schemeFile.writeAsStringSync(content);
    print('iOS scheme created: $flavorName.xcscheme');
  }

  /// Patches Runner.xcscheme to add lldbInitFile to LaunchAction and TestAction
  /// if not already present. Called before generating flavor schemes so copies
  /// automatically inherit the setting.
  static void patchRunnerScheme(String xcodeProjectPath) {
    final schemeFile = File(
      path.join(xcodeProjectPath, 'xcshareddata', 'xcschemes', 'Runner.xcscheme'),
    );
    if (!schemeFile.existsSync()) return;

    var content = schemeFile.readAsStringSync();
    const lldb = 'lldbInitFile = "\$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"';

    if (content.contains('lldbInitFile')) {
      print('Runner.xcscheme already has lldbInitFile, skipping.');
      return;
    }

    content = content.replaceFirstMapped(
      RegExp(r'(<LaunchAction\b[^>]*?)(>)', dotAll: true),
      (m) => '${m.group(1)}\n      $lldb${m.group(2)}',
    );
    content = content.replaceFirstMapped(
      RegExp(r'(<TestAction\b[^>]*?)(>)', dotAll: true),
      (m) => '${m.group(1)}\n      $lldb${m.group(2)}',
    );

    schemeFile.writeAsStringSync(content);
    print('Runner.xcscheme patched with lldbInitFile.');
  }

  static void remove(String xcodeProjectPath, String flavorName) {
    final schemeFile = File(
      path.join(xcodeProjectPath, 'xcshareddata', 'xcschemes', '$flavorName.xcscheme'),
    );
    if (schemeFile.existsSync()) {
      schemeFile.deleteSync();
      print('iOS scheme removed: $flavorName.xcscheme');
    }
  }
}