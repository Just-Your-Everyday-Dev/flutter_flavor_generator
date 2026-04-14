import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_flavor_gen/src/cli/prompts.dart';
import 'package:flutter_flavor_gen/src/generators/flavor_config_generator.dart';
import 'package:flutter_flavor_gen/src/generators/flutter_value_generators.dart';
import 'package:flutter_flavor_gen/src/generators/main_generator.dart';
import 'package:flutter_flavor_gen/src/generators/main_rewriter.dart';
import 'package:flutter_flavor_gen/src/generators/android/gradle_generator.dart';
import 'package:flutter_flavor_gen/src/generators/ios/xcscheme_generator.dart';
import 'package:flutter_flavor_gen/src/generators/ios/pbxproj_generator.dart';
import 'package:flutter_flavor_gen/src/generators/run_config_generator.dart';
import 'package:flutter_flavor_gen/src/models/flavor.dart';
import 'package:flutter_flavor_gen/src/models/flavor_parameter.dart';
import 'package:flutter_flavor_gen/src/utils/config_manager.dart';
import 'package:flutter_flavor_gen/src/utils/file_utils.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addCommand('create')
    ..addCommand('add-flavor')
    ..addCommand('update')
    ..addCommand('remove-flavor');


  final results = parser.parse(args);
  final root = Directory.current.path;
  final config = ConfigManager(projectRoot: root);

  switch (results.command?.name) {
    case 'add-flavor':
      _handleAddFlavor(config, root);
      break;
    case 'update':
      _handleUpdate(config, root);
      break;
    case 'remove-flavor':
      _handleRemoveFlavor(config, root);
      break;
    default:
      _handleCreate(config, root);
  }
}

void _handleCreate(ConfigManager config, String root) {
  if (config.exists) {
    print('Flavors already exist. Use "add-flavor" or "update".');
    exit(1);
  }

  final gradlePath = FileUtils.resolveAndroidPath(root);
  if (gradlePath == null) {
    print('android/app/build.gradle not found. Run this from your Flutter project root.');
    exit(1);
  }

  final xcodeProject = FileUtils.resolveIosPath(root);
  if (xcodeProject == null) {
    print('ios/Runner.xcodeproj not found. Run this from your Flutter project root.');
    exit(1);
  }

  final flavors = Prompts.collectFlavors();
  final lib = FileUtils.resolveLibPath(root);

  FileUtils.writeFile(
    path.join(lib, 'flavors', 'flavor_values.dart'),
    FlavorValuesGenerator.generate(flavors),
  );
  FileUtils.writeFile(
    path.join(lib, 'flavors', 'flavor_config.dart'),
    FlavorConfigGenerator.generate(flavors),
  );
  for (final f in flavors) {
    FileUtils.writeFile(
      path.join(lib, 'main_${f.name}.dart'),
      MainGenerator.generate(f),
    );
  }
  MainRewriter.rewrite(path.join(lib, 'main.dart'));
  MainRewriter.updateWidgetTestImport(path.join(root, 'test', 'widget_test.dart'));

  GradleGenerator.applyFlavors(gradlePath, flavors);

  for (final f in flavors) {
    XcschemeGenerator.generate(xcodeProject, f.name);
  }
  PbxprojGenerator.applyFlavors(xcodeProject, flavors);

  for (final f in flavors) {
    RunConfigGenerator.generate(root, f.name);
  }

  config.saveFlavors(flavors);
  print('Done. Check lib/flavors/, lib/main_*.dart, android/, and ios/');
}

void _handleAddFlavor(ConfigManager config, String root) {
  if (!config.exists) {
    print('Run "create" first.');
    exit(1);
  }

  final gradlePath = FileUtils.resolveAndroidPath(root);
  if (gradlePath == null) {
    print('android/app/build.gradle not found. Run this from your Flutter project root.');
    exit(1);
  }

  final xcodeProject = FileUtils.resolveIosPath(root);
  if (xcodeProject == null) {
    print('ios/Runner.xcodeproj not found. Run this from your Flutter project root.');
    exit(1);
  }

  final existing = config.loadFlavors();
  final newFlavor = Prompts.collectNewFlavor(existing);
  final all = [...existing, newFlavor];
  final lib = FileUtils.resolveLibPath(root);

  FileUtils.writeFile(
    path.join(lib, 'main_${newFlavor.name}.dart'),
    MainGenerator.generate(newFlavor),
  );
  FileUtils.writeFile(
    path.join(lib, 'flavors', 'flavor_config.dart'),
    FlavorConfigGenerator.generate(all),
  );

  GradleGenerator.applyFlavors(gradlePath, all);
  XcschemeGenerator.generate(xcodeProject, newFlavor.name);
  PbxprojGenerator.applyFlavors(xcodeProject, all);
  RunConfigGenerator.generate(root, newFlavor.name);

  config.saveFlavors(all);
  print('Flavor "${newFlavor.name}" added.');
}

void _handleRemoveFlavor(ConfigManager config, String root) {
  if (!config.exists) {
    print('Run "create" first.');
    exit(1);
  }

  final gradlePath = FileUtils.resolveAndroidPath(root);
  if (gradlePath == null) {
    print('android/app/build.gradle not found. Run this from your Flutter project root.');
    exit(1);
  }

  final xcodeProject = FileUtils.resolveIosPath(root);
  if (xcodeProject == null) {
    print('ios/Runner.xcodeproj not found. Run this from your Flutter project root.');
    exit(1);
  }

  final existing = config.loadFlavors();
  final flavorName = Prompts.collectFlavorToRemove(existing);
  final remaining = existing.where((f) => f.name != flavorName).toList();
  final lib = FileUtils.resolveLibPath(root);
  final isLast = remaining.isEmpty;

  final mainFile = File(path.join(lib, 'main_$flavorName.dart'));
  if (mainFile.existsSync()) mainFile.deleteSync();

  if (isLast) {
    MainRewriter.revertToMain(lib);
    MainRewriter.revertWidgetTestImport(path.join(root, 'test', 'widget_test.dart'));
    File(path.join(lib, 'flavors', 'flavor_values.dart')).deleteSync();
    File(path.join(lib, 'flavors', 'flavor_config.dart')).deleteSync();
  } else {
    FileUtils.writeFile(
      path.join(lib, 'flavors', 'flavor_config.dart'),
      FlavorConfigGenerator.generate(remaining),
    );
  }

  GradleGenerator.removeFlavor(gradlePath, flavorName, isLast: isLast);
  XcschemeGenerator.remove(xcodeProject, flavorName);
  PbxprojGenerator.removeFlavor(xcodeProject, flavorName);
  RunConfigGenerator.remove(root, flavorName);

  if (isLast) {
    config.delete();
    print('All flavors removed. Project restored to single-flavor setup.');
  } else {
    config.saveFlavors(remaining);
    print('Flavor "$flavorName" removed.');
  }
}

void _handleUpdate(ConfigManager config, String root) {
  if (!config.exists) {
    print('Run "create" first.');
    exit(1);
  }

  final flavors = config.loadFlavors();
  final update = Prompts.collectUpdateInfo(flavors);

  final updated = flavors.map((f) {
    if (f.name != update.flavorName) return f;
    return Flavor(
      name: f.name,
      parameters: f.parameters.map((p) {
        if (p.name != update.paramName) return p;
        return FlavorParameter(name: p.name, type: p.type, value: update.newValue);
      }).toList(),
    );
  }).toList();

  final updatedFlavor = updated.firstWhere((f) => f.name == update.flavorName);
  FileUtils.writeFile(
    path.join(FileUtils.resolveLibPath(root), 'main_${updatedFlavor.name}.dart'),
    MainGenerator.generate(updatedFlavor),
  );

  config.saveFlavors(updated);
  print('Updated ${update.flavorName}.${update.paramName} to "${update.newValue}"');
}