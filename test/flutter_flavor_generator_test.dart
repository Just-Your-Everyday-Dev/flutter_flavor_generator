import 'package:flutter_flavor_gen/flutter_flavor_gen.dart';
import 'package:test/test.dart';

void main() {
  group('Flavor model', () {
    test('Flavor serializes and deserializes correctly', () {
      const param = FlavorParameter(name: 'apiUrl', type: 'String', value: 'https://example.com');
      const flavor = Flavor(name: 'dev', parameters: [param]);

      final json = flavor.toJson();
      final restored = Flavor.fromJson(json);

      expect(restored.name, equals('dev'));
      expect(restored.parameters.first.name, equals('apiUrl'));
      expect(restored.parameters.first.value, equals('https://example.com'));
    });
  });
}