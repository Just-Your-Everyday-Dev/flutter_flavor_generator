import 'flavor_parameter.dart';

/// Represents a single app flavor with a name and a set of typed parameters.
class Flavor {
  /// The unique identifier for this flavor (e.g. `dev`, `staging`, `prod`).
  final String name;

  /// The list of typed parameters associated with this flavor.
  final List<FlavorParameter> parameters;

  /// Creates a [Flavor] with the given [name] and [parameters].
  const Flavor({required this.name, required this.parameters});

  /// Serializes this flavor to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'parameters': parameters.map((p) => p.toJson()).toList(),
      };

  /// Creates a [Flavor] from a JSON map produced by [toJson].
  factory Flavor.fromJson(Map<String, dynamic> json) => Flavor(
        name: json['name'] as String,
        parameters: (json['parameters'] as List)
            .map((p) => FlavorParameter.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}