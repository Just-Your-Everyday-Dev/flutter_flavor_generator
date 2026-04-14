import 'dart:convert';
import 'dart:io';
import '../models/flavor.dart';

const _configFileName = '.dart_flavors.json';

class ConfigManager {
  final String projectRoot;
  ConfigManager({required this.projectRoot});

  File get _configFile => File('$projectRoot/$_configFileName');
  bool get exists => _configFile.existsSync();

  List<Flavor> loadFlavors() {
    if (!exists) return [];
    final json = jsonDecode(_configFile.readAsStringSync()) as Map<String, dynamic>;
    return (json['flavors'] as List)
        .map((f) => Flavor.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  void saveFlavors(List<Flavor> flavors) {
    _configFile.writeAsStringSync(jsonEncode({
      'version': '1.0.0',
      'flavors': flavors.map((f) => f.toJson()).toList(),
    }));
  }

  void delete() {
    if (exists) _configFile.deleteSync();
  }
}