import 'flavor_parameter.dart';

class Flavor {
  final String name;
  final List<FlavorParameter> parameters;

  const Flavor({required this.name, required this.parameters});

  Map<String, dynamic> toJson() => {
        'name': name,
        'parameters': parameters.map((p) => p.toJson()).toList(),
      };

  factory Flavor.fromJson(Map<String, dynamic> json) => Flavor(
        name: json['name'] as String,
        parameters: (json['parameters'] as List)
            .map((p) => FlavorParameter.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}