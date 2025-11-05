#!/bin/bash

# Get secrets from Doppler
CLIENT_ID=$(doppler secrets get LINEAR_CLIENT_ID --plain 2>/dev/null)
CLIENT_SECRET=$(doppler secrets get LINEAR_CLIENT_SECRET --plain 2>/dev/null)

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo "Error: Could not fetch secrets from Doppler"
    echo "Make sure Doppler is configured: doppler setup"
    exit 1
fi

# Create xcschemes directory if it doesn't exist
mkdir -p LinearBar.xcodeproj/xcshareddata/xcschemes

# Create or update the scheme file
cat > LinearBar.xcodeproj/xcshareddata/xcschemes/LinearBar.xcscheme << SCHEME
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1540"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "FF0001"
               BuildableName = "LinearBar.app"
               BlueprintName = "LinearBar"
               ReferencedContainer = "container:LinearBar.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "FF0001"
            BuildableName = "LinearBar.app"
            BlueprintName = "LinearBar"
            ReferencedContainer = "container:LinearBar.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "LINEAR_CLIENT_ID"
            value = "$CLIENT_ID"
            isEnabled = "YES">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "LINEAR_CLIENT_SECRET"
            value = "$CLIENT_SECRET"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "FF0001"
            BuildableName = "LinearBar.app"
            BlueprintName = "LinearBar"
            ReferencedContainer = "container:LinearBar.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
SCHEME

echo "✅ Xcode scheme configured with Doppler secrets"
echo "   LINEAR_CLIENT_ID: ${CLIENT_ID:0:10}..."
echo "   LINEAR_CLIENT_SECRET: ${CLIENT_SECRET:0:10}..."
echo ""
echo "ℹ️  Close and reopen Xcode to load the new scheme"
echo "   Then run the app normally with ⌘R"
