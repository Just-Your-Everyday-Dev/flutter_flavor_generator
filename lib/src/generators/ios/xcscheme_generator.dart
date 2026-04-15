import 'dart:io';
import 'package:path/path.dart' as path;

class XcschemeGenerator {
  static void generate(String xcodeProjectPath, String flavorName) {
    final schemesDir = path.join(xcodeProjectPath, 'xcshareddata', 'xcschemes');
    final schemeFile = File(path.join(schemesDir, '$flavorName.xcscheme'));

    if (schemeFile.existsSync()) {
      print('iOS scheme for $flavorName already exists, skipping.');
      return;
    }

    Directory(schemesDir).createSync(recursive: true);
    schemeFile.writeAsStringSync(_template(flavorName));
    print('iOS scheme created: $flavorName.xcscheme');
  }

  static void remove(String xcodeProjectPath, String flavorName) {
    final schemeFile = File(
      path.join(xcodeProjectPath, 'xcshareddata', 'xcschemes', '$flavorName.xcscheme'),
    );
    if (schemeFile.existsSync()) {
      schemeFile.deleteSync();
      print('iOS scheme removed: $flavorName.xcscheme');
    }
  }

  static String _template(String flavorName) => '''
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1510" version="1.3">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES"
            buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference
               BuildableIdentifier="primary"
               BlueprintIdentifier="97C146ED1CF9000F007C117D"
               BuildableName="Runner.app"
               BlueprintName="Runner"
               ReferencedContainer="container:Runner.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration="Debug-$flavorName"
      selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB"
      lldbInitFile = "\$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"
      shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration="Debug-$flavorName"
      selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB"
      lldbInitFile = "\$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"
      launchStyle="0"
      useCustomWorkingDirectory="NO"
      ignoresPersistentStateOnLaunch="NO"
      debugDocumentVersioning="YES"
      debugServiceExtension="internal"
      allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference
            BuildableIdentifier="primary"
            BlueprintIdentifier="97C146ED1CF9000F007C117D"
            BuildableName="Runner.app"
            BlueprintName="Runner"
            ReferencedContainer="container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration="Profile-$flavorName"
      shouldUseLaunchSchemeArgsEnv="YES"
      savedToolIdentifier=""
      useCustomWorkingDirectory="NO"
      debugDocumentVersioning="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference
            BuildableIdentifier="primary"
            BlueprintIdentifier="97C146ED1CF9000F007C117D"
            BuildableName="Runner.app"
            BlueprintName="Runner"
            ReferencedContainer="container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration="Debug-$flavorName">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration="Release-$flavorName" revealArchiveInOrganizer="YES">
   </ArchiveAction>
</Scheme>
''';
}