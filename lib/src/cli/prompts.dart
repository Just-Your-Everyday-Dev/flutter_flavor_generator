import 'package:interact/interact.dart';
import '../models/flavor.dart';
import '../models/flavor_parameter.dart';

class Prompts {
  static List<Flavor> collectFlavors() {
    final count = int.parse(Input(
      prompt: 'How many flavors do you want to create?',
      validator: (v) {
        if (int.tryParse(v) == null || int.parse(v) < 1) {
          throw ValidationError('Enter a number greater than 0');
        }
        return true;
      },
    ).interact());

    final paramNames = <String>[];
    final flavors = <Flavor>[];

    for (int i = 0; i < count; i++) {
      print('\n--- Flavor ${i + 1} ---');

      final name = Input(
        prompt: 'Flavor name (e.g. dev, staging, prod):',
        validator: _nameValidator,
      ).interact();

      if (i == 0) {
        print('\nDefine parameter names (shared across all flavors):');
        print('e.g. appName, apiUrl, primaryColor — empty line when done\n');
        while (true) {
          final p = Input(prompt: 'Parameter name (Enter to finish):').interact();
          if (p.trim().isEmpty) break;
          if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(p.trim())) {
            print('Invalid identifier, skipping');
            continue;
          }
          paramNames.add(p.trim());
        }
      }

      final parameters = <FlavorParameter>[];
      for (final paramName in paramNames) {
        final typeIdx = Select(
          prompt: '  Type for "$paramName":',
          options: ['String', 'int', 'double', 'bool'],
        ).interact();
        final type = ['String', 'int', 'double', 'bool'][typeIdx];
        final value = Input(
          prompt: '  Value for "$paramName" ($type) in "${name.trim()}":',
        ).interact();
        parameters.add(FlavorParameter(name: paramName, type: type, value: value.trim()));
      }

      flavors.add(Flavor(name: name.trim(), parameters: parameters));
    }
    return flavors;
  }

  static Flavor collectNewFlavor(List<Flavor> existingFlavors) {
    final existingNames = existingFlavors.map((f) => f.name).toSet();
    final paramNames = existingFlavors.first.parameters.map((p) => p.name).toList();

    final name = Input(
      prompt: 'New flavor name:',
      validator: (v) {
        if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(v.trim())) {
          throw ValidationError('Invalid identifier');
        }
        if (existingNames.contains(v.trim())) {
          throw ValidationError('Flavor "${v.trim()}" already exists');
        }
        return true;
      },
    ).interact();

    final parameters = <FlavorParameter>[];
    for (final paramName in paramNames) {
      final existing = existingFlavors.first.parameters.firstWhere((p) => p.name == paramName);
      final value = Input(
        prompt: '  Value for "$paramName" (${existing.type}) in "${name.trim()}":',
      ).interact();
      parameters.add(FlavorParameter(name: paramName, type: existing.type, value: value.trim()));
    }

    return Flavor(name: name.trim(), parameters: parameters);
  }

  static ({String flavorName, String paramName, String newValue}) collectUpdateInfo(
    List<Flavor> flavors,
  ) {
    final flavorIdx = Select(
      prompt: 'Which flavor to update?',
      options: flavors.map((f) => f.name).toList(),
    ).interact();

    final flavor = flavors[flavorIdx];
    final paramIdx = Select(
      prompt: 'Which parameter to update?',
      options: flavor.parameters.map((p) => '${p.name} (current: "${p.value}")').toList(),
    ).interact();

    final param = flavor.parameters[paramIdx];
    final newValue = Input(
      prompt: 'New value for "${param.name}":',
    ).interact();

    return (flavorName: flavor.name, paramName: param.name, newValue: newValue.trim());
  }

  static String collectFlavorToRemove(List<Flavor> flavors) {
    final idx = Select(
      prompt: 'Which flavor do you want to remove?',
      options: flavors.map((f) => f.name).toList(),
    ).interact();
    return flavors[idx].name;
  }

  static bool _nameValidator(String v) {
    if (v.trim().isEmpty) throw ValidationError('Name cannot be empty');
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(v.trim())) {
      throw ValidationError('Letters, numbers, underscores only; must start with a letter');
    }
    return true;
  }
}