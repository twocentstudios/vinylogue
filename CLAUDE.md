- ALWAYS run xcodegen after adding/removing/renaming files IGNORING THE OUTPUT.
- ALWAYS run swiftformat on all changed files before building IGNORING THE OUTPUT. If the command fails, run it again and read the error.
- DO NOT run swiftformat on any files in ./DerivedData
- NEVER run UI tests unless I specifically request it.
- NEVER look in ./DerivedData UNLESS you are looking at package documentation, the tmp directory, or trying to determine the cause of a build error.
- NEVER write UI tests until you have confirmed with me that the UI is 100% correct.
- ALWAYS update the CLAUDE.MD file in each directory after refactoring, adding, or deleting files.

## iOS Build Configuration

### Project Details
- **Project File**: `Vinylogue.xcodeproj`
- **Scheme**: `Vinylogue`
- **Bundle ID**: `com.twocentstudios.vinylogue`

### Simulator Configuration
- **Default Simulator UDID**: `DB0531E0-B47E-42AC-9AAB-FEB76D3D563A`
- **Simulator Name**: iPhone 17 Pro (iOS 26.2)

### Build Paths
- **DerivedData Path**: `DerivedData`
- **App Binary Path**: `DerivedData/Build/Products/Debug-iphonesimulator/Vinylogue.app`

### Command Examples

Build only:
```bash
xcodebuild -project Vinylogue.xcodeproj -scheme "Vinylogue" -destination "platform=iphonesimulator,id=DB0531E0-B47E-42AC-9AAB-FEB76D3D563A" -derivedDataPath DerivedData -configuration Debug build 2>&1 | xcsift -w
```

Install:
```bash
xcrun simctl install DB0531E0-B47E-42AC-9AAB-FEB76D3D563A "DerivedData/Build/Products/Debug-iphonesimulator/Vinylogue.app"
```

Launch:
```bash
xcrun simctl launch --terminate-running-process DB0531E0-B47E-42AC-9AAB-FEB76D3D563A com.twocentstudios.vinylogue
```