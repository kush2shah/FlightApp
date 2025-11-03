# FlightApp Technical Stack

## Core Technologies
- **Platform**: iOS (SwiftUI)
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Mapping**: MapKit
- **Async**: Combine, async/await
- **Haptics**: CoreHaptics, UIKit Feedback Generators

## Architecture
- **Pattern**: MVVM (Model-View-ViewModel)
- **Async Operations**: async/await for modern concurrency
- **State Management**: SwiftUI @State, @StateObject, @ObservedObject, @AppStorage
- **Dependency Management**: Native Xcode (no external package managers detected)

## External APIs
- **FlightAware AeroAPI**: Real-time flight data, route information
- **SeatsAero API**: Additional flight/seat data (SeatsAeroAPIService present)

## Key Services
- **AeroAPIService**: Flight data fetching with caching and date filtering
- **AeroAPICacheService**: Caching layer for API responses
- **WaypointDatabaseService**: International waypoint resolution
- **AirlineService**: Airline information management
- **AirlineLogoService**: Airline logo retrieval
- **AirlineColorService**: Airline brand color management
- **HapticManager**: Centralized haptic feedback with glass-specific patterns
- **PopularRouteStore**: Sample/featured flight management
- **RecentSearchStore**: Search history management
- **RequestDeduplicator**: Prevents duplicate API requests

## Data Models
- **AeroFlight**: FlightAware API response models with null-safety
- **FlightTime**: Time/date formatting with timezone support
- **WaypointData**: Navigation database entries
- **AirlineProfile**: Airline branding and metadata
- **AirlineBrandColors**: Airline color themes

## UI Components
- **GlassEffectContainer**: Liquid glass effect wrapper
- **FlightView**: Detailed flight information display
- **FlightSearchView_Redesigned**: Hero search experience
- **RouteView**: Route visualization with maps
- **AirlineProfileView**: Airline branding displays
- Various specialized flight cards (Hero, Route, Aircraft, Gate/Terminal)

## Development Tools
- **Xcode**: Primary IDE (project uses .xcodeproj)
- **Git**: Version control
- No SwiftLint or swift-format detected (no linting/formatting automation)
