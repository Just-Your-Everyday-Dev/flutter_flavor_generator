class FlavorParameter {
  final String name;
  final String type;
  final String value;

  const FlavorParameter({
    required this.name,
    required this.type,
    required this.value,
  });

  Map<String, dynamic> toJson() => {'name': name, 'type': type, 'value': value};

  factory FlavorParameter.fromJson(Map<String, dynamic> json) => FlavorParameter(
        name: json['name'] as String,
        type: json['type'] as String,
        value: json['value'] as String,
      );
}