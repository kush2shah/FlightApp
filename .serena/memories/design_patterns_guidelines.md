# FlightApp - Design Patterns & Guidelines

## Architecture Patterns

### MVVM (Model-View-ViewModel)
The app follows MVVM architecture:
- **Models**: Data structures in `Models/Flights/` (AeroFlight, FlightTime)
- **Views**: SwiftUI views in `Views/` hierarchy
- **ViewModels**: Business logic in `ViewModels/` (FlightViewModel, RouteViewModel)

ViewModels manage:
- API calls to services
- Data transformation
- State management for views
- Async operations

### Singleton Pattern
Used extensively for shared services:
```swift
class ServiceName {
    static let shared = ServiceName()
    private init() { }
}
```

Examples:
- `HapticManager.shared`
- `AeroAPIService.shared`
- Used for stateless services or app-wide shared state

### Service Layer Pattern
All external dependencies isolated in `Services/`:
- API clients (AeroAPIService, SeatsAeroAPIService)
- Data services (WaypointDatabaseService, AirportCoordinateService)
- Utility managers (HapticManager, FeatureFlags)
- State stores (PopularRouteStore, RecentSearchStore)

Benefits:
- Testability (services can be mocked)
- Separation of concerns
- Reusability across views

### View Composition
SwiftUI views are composed of smaller, focused components:
- Card components (FlightRouteCard, FlightAircraftCard, FlightGateTerminalCard)
- Container views (GlassEffectContainer)
- Specialized views for each domain (Search, Flight, Route, Airline)

### View Extensions
Reusable view modifiers via extensions:
```swift
extension View {
    func brandedGlassEffect(...) -> some View { ... }
    func hapticFeedback(...) -> some View { ... }
}
```

## Design Principles

### Liquid Glass Design System
Core visual identity based on glass morphism:
- **GlassEffectContainer**: Standard wrapper for glass effects
- **GlassConstants**: Centralized corner radius and spacing values
- **Branded glass**: Airline color integration with glass materials
- **Native materials**: Uses `.ultraThinMaterial` for iOS-native glass

### Haptic Feedback Philosophy
"Aggressive, experience-defining" haptic patterns:
- Glass-specific patterns (glassClick, glassForming, glassBreaking)
- Contextual feedback (search, cards, sheets)
- Configurable intensity (off, subtle, normal, aggressive)
- Custom patterns via CoreHaptics for unique effects

### Airline Branding Integration
Airline identity throughout the app:
- `AirlineBrandColors`: Color theming per airline
- `AirlineLogoService`: Logo display
- Branded glass effects with airline colors
- Consistent branding in cards and views

## State Management

### SwiftUI Property Wrappers
- `@State`: Local view state
- `@StateObject`: View owns the ObservableObject
- `@ObservedObject`: View observes external ObservableObject
- `@AppStorage`: UserDefaults-backed persistent state
- `@Environment`: Environment values

### Async/Await Pattern
Modern Swift concurrency:
```swift
func fetchData() async throws -> Data {
    // Async operations
}

Task {
    do {
        let data = try await fetchData()
    } catch {
        // Handle error
    }
}
```

Used throughout services and ViewModels.

### Caching Strategy
Multi-layer caching:
- `AeroAPICacheService`: In-memory cache for API responses
- `RequestDeduplicator`: Prevents duplicate in-flight requests
- Reduces API calls and improves performance

## Error Handling

### Service Errors
Custom error enums:
```swift
enum AeroAPIError: Error {
    case invalidResponse
    case networkError
    // etc.
}
```

### UI Error Handling
- `FlightErrorView`: Dedicated error state view
- Graceful degradation
- User-friendly error messages
- Print statements for debugging (logged to Xcode console)

## Constants & Configuration

### Constants Pattern
Dedicated structs for magic numbers:
```swift
struct GlassConstants {
    static let defaultCornerRadius: CGFloat = 20
    static let cardCornerRadius: CGFloat = 24
    // ...
}
```

Avoids magic numbers scattered in code.

### Configuration Files
- `.xcconfig` files for build configuration
- `Config-Template.xcconfig` for API keys (not committed)
- `FeatureFlags.swift` for runtime feature toggles

## Code Organization

### MARK Comments
Extensive use for section organization:
```swift
// MARK: - Section Name
// MARK: Section Name (without dash for subsections)
```

Examples:
- `// MARK: - API Endpoints`
- `// MARK: - Glass-Specific Patterns`
- `// MARK: - Supporting Types`

### File Organization
Typical file structure:
1. Imports
2. Main class/struct definition
3. MARK sections for logical grouping
4. Extensions
5. Supporting types (if small and related)

## Naming Conventions

### Prefixes & Suffixes
- **Service**: Classes providing business logic (AeroAPIService, WaypointDatabaseService)
- **Manager**: Singleton utility classes (HapticManager)
- **Store**: State storage classes (PopularRouteStore, RecentSearchStore)
- **View**: SwiftUI views (FlightView, RouteView)
- **ViewModel**: MVVM view models (FlightViewModel, RouteViewModel)
- **Card**: Card-style UI components (FlightRouteCard)

### Method Naming
- Clear, descriptive names
- Verb-based for actions: `getFlightInfo`, `fetchData`
- State-based for properties: `isLoading`, `hasError`
- Swift API guidelines followed

## Testing Approach

### Current State
Minimal automated testing:
- `FlightAppTests.swift` exists but limited coverage
- Primary testing is manual via simulator
- No UI testing automation in practice

### Manual Testing
- Use known test flights: AA1, UA60, BA175
- Test on appropriate device simulators
- Verify visual design (glass effects)
- Check haptic feedback
- Test error states and edge cases

## Data Loading

### CSV-Based Data
- `international_waypoints.csv`: 31,774+ waypoints
- `complete_navigation_database.csv`: Full nav database
- Loaded at app startup or on-demand
- Fallback mechanisms for missing data

### API Data
- Real-time from FlightAware AeroAPI
- Cached to reduce API calls
- Date-filtered for relevant flights only
- Null-safe parsing (proper Optional handling)

## Performance Considerations

### Lazy Loading
- Views load data on-demand
- MapKit annotations added incrementally
- Large datasets loaded asynchronously

### Request Optimization
- `RequestDeduplicator`: Prevents duplicate requests
- `AeroAPICacheService`: In-memory caching
- Date filtering on API calls to reduce response size

### Haptic Efficiency
- Pre-warmed generators for instant response
- Intensity-based filtering (off/subtle modes skip effects)
- Async Task blocks for complex patterns without blocking UI
