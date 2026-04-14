import 'dart:io';
import 'package:path/path.dart' as path;

class RunConfigGenerator {
  static void generate(String projectRoot, String flavorName) {
    final dir = Directory(path.join(projectRoot, '.idea', 'runConfigurations'));
    dir.createSync(recursive: true);

    final file = File(path.join(dir.path, '$flavorName.xml'));
    if (file.existsSync()) {
      print('Run config for $flavorName already exists, skipping.');
      return;
    }

    file.writeAsStringSync(_template(flavorName));
    print('Run config created: .idea/runConfigurations/$flavorName.xml');
  }

  static void remove(String projectRoot, String flavorName) {
    final file = File(
      path.join(projectRoot, '.idea', 'runConfigurations', '$flavorName.xml'),
    );
    if (file.existsSync()) {
      file.deleteSync();
      print('Run config removed: .idea/runConfigurations/$flavorName.xml');
    }
  }

  static String _template(String flavorName) => '''
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="$flavorName" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="additionalArgs" value="--flavor $flavorName" />
    <option name="buildFlavor" value="$flavorName" />
    <option name="filePath" value="\$PROJECT_DIR\$/lib/main_$flavorName.dart" />
    <method v="2" />
  </configuration>
</component>
''';
}