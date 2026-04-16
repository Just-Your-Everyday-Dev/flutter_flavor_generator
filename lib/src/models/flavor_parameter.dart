/// A typed key-value parameter belonging to a [Flavor].
class FlavorParameter {
  /// The parameter name (e.g. `apiBaseUrl`).
  final String name;

  /// The Dart type of this parameter (e.g. `String`, `int`, `bool`).
  final String type;

  /// The value assigned to this parameter for a specific flavor.
  final String value;

  /// Creates a [FlavorParameter] with the given [name], [type], and [value].
  const FlavorParameter({
    required this.name,
    required this.type,
    required this.value,
  });

  /// Serializes this parameter to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'name': name, 'type': type, 'value': value};

  /// Creates a [FlavorParameter] from a JSON map produced by [toJson].
  factory FlavorParameter.fromJson(Map<String, dynamic> json) => FlavorParameter(
        name: json['name'] as String,
        type: json['type'] as String,
        value: json['value'] as String,
      );
}