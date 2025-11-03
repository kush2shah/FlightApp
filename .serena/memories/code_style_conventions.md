# FlightApp Code Style & Conventions

## File Header Convention
All Swift files include a standard header:
```swift
//
//  FileName.swift
//  FlightApp
//
//  Created by Kush Shah on [date].
//
```

## Naming Conventions
- **Classes/Structs/Enums**: PascalCase (e.g., `AeroAPIService`, `HapticManager`, `FlightViewModel`)
- **Properties/Methods**: camelCase (e.g., `baseURL`, `getFlightInfo`, `glassClick`)
- **Constants**: camelCase static properties (e.g., `shared` for singletons)
- **Private properties**: camelCase with no prefix (e.g., `heavyImpact`, `engine`)

## Code Organization
- **MARK comments**: Used extensively to organize code sections
  - Example: `// MARK: - Basic Haptics`, `// MARK: - Glass-Specific Patterns`
- **Namespaces**: Used for logical grouping (e.g., `// MARK: - Route Endpoints`)
- **File structure**: Typically includes class/struct definition, followed by extensions

## Documentation Style
- **Doc comments**: Triple-slash `///` comments for public APIs and complex methods
- **Inline comments**: Single-line `//` comments for implementation details
- **Descriptive docstrings**: Used for complex classes/methods (e.g., HapticManager methods)

## Swift Features & Patterns
- **Property wrappers**: Heavy use of SwiftUI property wrappers (@State, @StateObject, @AppStorage)
- **Singletons**: Common pattern with `static let shared` (e.g., HapticManager, AeroAPIService)
- **Extensions**: Used for adding functionality to Views and other types
- **ViewBuilder**: Used for custom View initializers
- **Enums**: Used for configuration and type safety (e.g., HapticIntensity, AeroAPIError)
- **Async/await**: Modern async patterns with Task blocks
- **Error handling**: do-catch blocks with print statements for logging

## SwiftUI View Conventions
- **View composition**: Small, focused view components
- **Custom containers**: Wrapper views for consistent styling (GlassEffectContainer)
- **View extensions**: Used for reusable modifiers (e.g., `.brandedGlassEffect()`)
- **Constants**: Dedicated structs for magic numbers (e.g., GlassConstants)

## Type Safety
- **Optional handling**: Proper use of `guard`, `if let`, and optional chaining
- **Type inference**: Leveraged but explicit types used for clarity in complex cases
- **Structs for data**: Models use structs (value types) rather than classes

## Access Control
- **Private**: Used liberally for internal implementation details
- **Public/Internal**: Default for APIs that need to be accessed from other files
- **Static**: Used for shared instances and utility methods

## Constants & Configuration
- **Magic numbers**: Extracted to named constants in dedicated Constants structs
- **AppStorage**: Used for user preferences (e.g., haptic intensity)
- **Environment**: Configuration via .xcconfig files (e.g., Config-Template.xcconfig for API keys)

## Comments & Code Clarity
- **Self-documenting code**: Clear naming preferred over excessive comments
- **Complex logic comments**: Added where behavior isn't immediately obvious
- **TODO/FIXME**: Not observed in sample code, but would follow standard conventions
