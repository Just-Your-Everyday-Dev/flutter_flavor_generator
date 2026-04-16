## 0.1.2

- Added dartdoc comments to all public API elements

## 0.1.1

- Fixed iOS scheme generation: flavor schemes are now copied from `Runner.xcscheme` instead of a hardcoded template, ensuring correct `BlueprintIdentifier`, up-to-date scheme format, and automatic inheritance of `lldbInitFile` for Flutter debug mode on iOS
- Added `patchRunnerScheme()` to insert `lldbInitFile` into `Runner.xcscheme` if missing

## 0.1.0

- Initial release
- `create`: generates Dart flavor files, Android `build.gradle` product flavors, iOS schemes + build configurations, and Android Studio run configurations
- `add-flavor`: safely adds a new flavor to an existing setup
- `update`: updates a single parameter value for a flavor
- `remove-flavor`: removes a flavor and reverts all generated files