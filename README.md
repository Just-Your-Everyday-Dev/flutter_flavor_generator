# flutter_flavor_gen

A Dart CLI tool that automates Flutter flavor setup. Add it as a `dev_dependency`, run one command from your Flutter project root, and it generates everything — Dart config files, Android `build.gradle` product flavors, iOS schemes, and Android Studio run configurations.

Safe to rerun — it never duplicates or corrupts existing files.

## What it generates

- `lib/flavors/flavor_values.dart` — data class with one field per parameter
- `lib/flavors/flavor_config.dart` — `AppFlavor` enum + `FlavorConfig` singleton
- `lib/main_<flavor>.dart` — entry point per flavor
- `lib/main_common.dart` — renamed from `main.dart`
- `android/app/build.gradle` — `productFlavors` block injected or merged
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/<Flavor>.xcscheme` — per flavor
- `ios/Runner.xcodeproj/project.pbxproj` — `Debug-<flavor>` / `Release-<flavor>` build configurations added
- `.idea/runConfigurations/<flavor>.xml` — Android Studio run config per flavor
- `.dart_flavors.json` — persists flavor data for safe reruns

## Installation

In your Flutter project's `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_flavor_gen: ^0.1.2
```

Then run:

```bash
dart pub get
```

## Usage

All commands must be run from your Flutter project root.

### Create flavors

```bash
dart run flutter_flavor_gen create
```

Walks you through defining flavor names, shared parameter names/types, and values per flavor. Generates all files listed above.

### Add a flavor

```bash
dart run flutter_flavor_gen add-flavor
```

Adds a new flavor to an existing setup. Only appends what's missing — never duplicates existing entries.

### Update a parameter value

```bash
dart run flutter_flavor_gen update
```

Updates a single parameter value for a specific flavor. Only rewrites the affected `main_<flavor>.dart`.

### Remove a flavor

```bash
dart run flutter_flavor_gen remove-flavor
```

Removes a flavor and all files generated for it. If it was the last flavor, reverts `main_common.dart` back to `main.dart` and restores the project to its original state.

## Example

After running `create` with two flavors (`dev` and `prod`) and parameters `appName` and `apiUrl`:

```dart
// lib/main_dev.dart
void main() {
  FlavorConfig(
    flavor: AppFlavor.dev,
    values: FlavorValues(
      appName: 'MyApp Dev',
      apiUrl: 'https://dev.api.example.com',
    ),
  );
  mainCommon();
}
```

```dart
// lib/flavors/flavor_config.dart
enum AppFlavor { dev, prod }

class FlavorConfig {
  static FlavorConfig get instance { /* ... */ }
  bool get isDev => flavor == AppFlavor.dev;
  bool get isProd => flavor == AppFlavor.prod;
}
```

Run with a specific flavor:

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

Or select the flavor directly from the Android Studio run configuration dropdown.

## Notes

- `prod` flavor does not get an `applicationIdSuffix` — its app ID stays as-is
- All other flavors get `.flavorName` appended (e.g. `com.example.app.dev`)
- After running on iOS, open Xcode and verify schemes appear under **Product → Scheme**
- The tool requires both `android/` and `ios/` directories to be present before running