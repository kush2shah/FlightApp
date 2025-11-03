# FlightApp Development Commands

**IMPORTANT**: Claude Code (CLI) cannot execute Xcode build commands, run simulators, or launch the app. These commands are for the user to run.

## Building & Running (User must execute)

### Build the project
```bash
xcodebuild -project FlightApp.xcodeproj -scheme FlightApp build
```

### Run tests
```bash
xcodebuild test -project FlightApp.xcodeproj -scheme FlightApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Clean build folder
```bash
xcodebuild clean -project FlightApp.xcodeproj -scheme FlightApp
```

## Running in Xcode (User must execute)
- Open `FlightApp.xcodeproj` in Xcode
- Select target device/simulator
- Press Cmd+R to build and run
- Press Cmd+U to run tests

## Version Control (Git) - Claude Code CAN execute these

### Check status
```bash
git status
```

### View recent commits
```bash
git log --oneline -10
```

### Create new branch
```bash
git checkout -b feature/your-feature-name
```

### Commit changes
```bash
git add .
git commit -m "Your commit message"
```

### Push to remote
```bash
git push origin branch-name
```

### Switch branches
```bash
git checkout branch-name
```

## Project Configuration

### Set up API key (User must do manually)
1. Copy `FlightApp/Config-Template.xcconfig` to `FlightApp/Config.xcconfig`
2. Update `AERO_API_KEY` with actual FlightAware API key
3. Config.xcconfig should be gitignored (not committed)

## File System Commands (macOS) - Claude Code CAN execute these

### List files
```bash
ls -la
```

### Find files
```bash
find . -name "*.swift" -type f
```

### Search in files
```bash
grep -r "pattern" --include="*.swift" .
```

### Navigate directories
```bash
cd path/to/directory
cd ..  # go up one level
pwd    # print working directory
```

## Code Quality

**Note**: No automated linting/formatting tools are currently configured for this project.

If you want to add SwiftLint (User must install):
```bash
# Install via Homebrew
brew install swiftlint

# Run from project root
swiftlint
```

## Simulator Commands (User must execute)

### List available simulators
```bash
xcrun simctl list devices
```

### Boot a simulator
```bash
xcrun simctl boot "iPhone 15"
```

### Open Simulator app
```bash
open -a Simulator
```

## Debugging (User must do in Xcode)

### View Xcode logs
- Run app in Xcode with Cmd+R
- Open Debug Console with Cmd+Shift+Y
- Print statements will appear here

### Clean derived data (fixes many Xcode issues)
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Useful Utilities - Claude Code CAN execute these

### Check Swift version
```bash
swift --version
```

### Check Xcode version
```bash
xcodebuild -version
```

### Format JSON output
```bash
echo '{"key":"value"}' | python3 -m json.tool
```

## Claude Code Capabilities Summary

**CAN do:**
- Git operations (status, commit, push, branch, log)
- File operations (read, write, search, find)
- Code analysis and editing
- Shell commands (ls, grep, find, etc.)

**CANNOT do:**
- Run Xcode builds
- Launch iOS Simulator
- Run the app
- Execute tests
- Open Xcode or interact with GUI
