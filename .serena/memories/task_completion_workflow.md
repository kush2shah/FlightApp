# FlightApp - Task Completion Workflow

## When a coding task is completed, follow these steps:

### 1. Code Review (Manual - by Claude Code)
Since there are no automated linting tools configured:
- Review code for consistency with existing style
- Check for proper error handling
- Verify naming conventions match project standards
- Ensure MARK comments are used for organization
- Confirm proper access control (private/public)

### 2. Request User to Build the Project
**IMPORTANT**: Claude Code (CLI) cannot execute Xcode build commands.
Ask the user to build the project:

"Please build the project in Xcode (Cmd+B) or run:
```bash
xcodebuild -project FlightApp.xcodeproj -scheme FlightApp build
```

Let me know if there are any build errors."

### 3. Request User to Run the App (Manual Testing)
Since this is an iOS app with UI components, ask the user to:
- Run in Xcode with Cmd+R
- Test on appropriate simulator (iPhone 15 or similar)
- Manually verify the feature works as expected
- Test edge cases and error states
- Check haptic feedback if applicable
- Verify glass effects render correctly

### 4. Request User to Run Tests (if applicable)
Ask the user to run tests in Xcode (Cmd+U) or via command line:
```bash
xcodebuild test -project FlightApp.xcodeproj -scheme FlightApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Note**: Currently only `FlightAppTests.swift` exists, minimal test coverage

### 5. User Verifies No Regressions
Ask the user to:
- Check that existing functionality still works
- Test related features that might be affected
- Ensure app doesn't crash on common workflows

### 6. Git Workflow
Only if user requests commit - Claude Code can handle git operations:

```bash
# Check what changed
git status
git diff

# Stage changes
git add [files]

# Commit with descriptive message following project style
git commit -m "Brief description of change"

# Examples from project history:
# "Fix time display text wrapping on smaller devices - v0.1"
# "Add liquid glass home page redesign with airline branding"
# "Display airline logos as borderless squares instead of circles"
```

### 7. Documentation Updates
If the change is significant:
- Update README.md if it affects features or setup
- Add comments for complex logic
- Update API documentation if public APIs changed

## Important Notes

### Claude Code Limitations
Claude Code (CLI) **CANNOT**:
- Run Xcode builds
- Launch the iOS Simulator
- Run the app
- Execute tests
- Interact with Xcode GUI

Claude Code **CAN**:
- Read and write code files
- Run git commands
- Search and analyze codebase
- Make code edits
- Read documentation

**Always rely on the user for build/run/test operations.**

### No Automated Checks
This project does NOT have:
- SwiftLint (no automated linting)
- swift-format (no automated formatting)
- CI/CD pipeline
- Pre-commit hooks

All quality checks are **manual**.

### API Keys
Ensure changes don't expose the AeroAPI key:
- Keep Config.xcconfig gitignored
- Never commit API keys to version control

### Testing Recommendations
For flight-related features, test with known working flights:
- **AA1** (JFK-LAX) - Domestic route
- **UA60** (SFO-MEL) - International long-haul
- **BA175** (LHR-JFK) - Transatlantic

### Branch Strategy
Based on git status and README:
- Main development on feature branches
- Current branch: `liquid-glass-haptics`
- Main branch: `main`
- Merge when feature is stable and tested

### When User Experiences Issues
Suggest cleaning build:
```bash
# Clean build folder
xcodebuild clean -project FlightApp.xcodeproj -scheme FlightApp

# Or clean derived data (more thorough)
rm -rf ~/Library/Developer/Xcode/DerivedData
```

Then rebuild the project.

## Quick Checklist (User must verify)
- [ ] Code builds without errors
- [ ] Code builds without warnings (address if reasonable)
- [ ] Manual testing completed
- [ ] No regressions in existing features
- [ ] Code follows project style conventions
- [ ] Proper error handling in place
- [ ] Tests updated (if applicable)
- [ ] Documentation updated (if needed)
- [ ] Git commit with clear message (if requested)
