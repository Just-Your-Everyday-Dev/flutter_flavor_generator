import 'dart:convert';
import 'dart:io';
import '../models/flavor.dart';

const _configFileName = '.dart_flavors.json';

/// Manages reading and writing the flavor configuration file for a Flutter project.
///
/// The configuration is stored as `.dart_flavors.json` in [projectRoot].
class ConfigManager {
  /// The absolute path to the root of the Flutter project.
  final String projectRoot;

  /// Creates a [ConfigManager] for the project at [projectRoot].
  ConfigManager({required this.projectRoot});

  File get _configFile => File('$projectRoot/$_configFileName');

  /// Whether the `.dart_flavors.json` configuration file exists.
  bool get exists => _configFile.existsSync();

  /// Loads and returns the list of flavors from the configuration file.
  ///
  /// Returns an empty list if the configuration file does not exist.
  List<Flavor> loadFlavors() {
    if (!exists) return [];
    final json = jsonDecode(_configFile.readAsStringSync()) as Map<String, dynamic>;
    return (json['flavors'] as List)
        .map((f) => Flavor.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  /// Persists [flavors] to the configuration file, overwriting any existing data.
  void saveFlavors(List<Flavor> flavors) {
    _configFile.writeAsStringSync(jsonEncode({
      'version': '1.0.0',
      'flavors': flavors.map((f) => f.toJson()).toList(),
    }));
  }

  /// Deletes the configuration file if it exists.
  void delete() {
    if (exists) _configFile.deleteSync();
  }
}