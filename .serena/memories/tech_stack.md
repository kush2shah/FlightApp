# FlightApp Technical Stack

## Core Technologies
- **Language**: Swift
- **Framework**: SwiftUI
- **Minimum iOS**: iOS 16+
- **Architecture**: MVVM (Model-View-ViewModel)
- **Async**: async/await, Task groups, Combine

## Apple Frameworks
- **MapKit**: Route visualization, airport annotations, great circle routes
- **CoreLocation**: Airport coordinates, distance calculations
- **CoreHaptics**: Custom haptic patterns (via HapticManager)
- **Foundation**: URLSession, Codable, DateFormatter

## External APIs
1. **FlightAware AeroAPI**
   - Real-time flight data
   - Flight status, schedules, positions
   - Route information with waypoints

2. **Amadeus Self-Service API**
   - Flight offers search
   - Cash pricing data
   - OAuth2 authentication
   - Test and production environments

3. **Seats.aero API**
   - Award availability search
   - Mileage program data
   - Multi-cabin class support

## Data Sources
- **International Waypoints**: CSV database with 31,774+ waypoints
- **Airport Database**: JSON with ~6000+ airports (IATA/ICAO codes, coordinates, metadata)
- **Airline Logos**: 600+ airline logo assets
- **Navigation Data**: VOR, DME, NDB reference points

## Services Architecture
### Core Services
- `AeroAPIService` - FlightAware API client with caching
- `AmadeusAPIService` - Amadeus API client with OAuth2
- `SeatsAeroAPIService` - Seats.aero API client
- `AeroAPICacheService` - API response caching layer
- `RequestDeduplicator` - Prevents duplicate simultaneous requests

### Data Services
- `AirportSearchService` - Intelligent airport search with fuzzy matching
- `WaypointDatabaseService` - International waypoint lookup
- `AirportCoordinateService` - Airport coordinate resolution
- `AircraftTypeService` - Aircraft type information
- `FlightNumberParser` - Parse flight numbers from text

### Airline Services
- `AirlineService` - Airline information
- `AirlineNameService` - Airline name lookup
- `AirlineLogoService` - Logo retrieval
- `AirlineColorService` - Brand color management

### Utility Services
- `HapticManager` - Centralized haptic feedback with custom patterns
- `FeatureFlags` - Feature toggle management
- `SearchInputParser` - Search query parsing
- `MileageProgramService` - Mileage program metadata

### Stores
- `PopularRouteStore` - Featured/sample flights
- `RecentSearchStore` - Search history
- `TrackedFlightsStore` - Saved flights for tracking

## Caching Strategy
- **In-Memory Cache**: NSCache with 1-hour TTL
- **Request Deduplication**: Prevents duplicate API calls
- **Token Caching**: OAuth2 tokens cached until expiration
- **Cache Keys**: Based on route, date, passenger count, cabin class

## Design System
- **Glass Morphism**: `.ultraThinMaterial`, `.regularMaterial`
- **SF Symbols**: For icons throughout
- **Custom Fonts**: SF Rounded (via `.sfRounded()` extension)
- **Haptic Patterns**: Custom `glassClick()`, `glassForming()`, `glassBreaking()`, `lightImpact()`
- **Airline Colors**: Dynamic theming based on airline branding

## Build Configuration
- **Config Files**: `Config.xcconfig` (gitignored, contains API keys)
- **Template**: `Config-Template.xcconfig` for setup guide
- **Xcode Project**: FlightApp.xcodeproj
- **Tests**: FlightAppTests, FlightAppUITests

## Development Tools
- **AI Assistant**: Claude Code for development assistance
- **Version Control**: Git with GitHub
- **MCP Servers**: Serena (code navigation), GitHub integration
