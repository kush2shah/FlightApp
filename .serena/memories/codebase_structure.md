# FlightApp Codebase Structure

## Top-Level Directory Structure
```
FlightApp/
├── FlightApp.xcodeproj/      # Xcode project configuration
├── FlightApp/                # Main application code
├── FlightAppTests/           # Unit tests
├── FlightAppUITests/         # UI tests
├── AeroAPI/                  # AeroAPI-related code/docs (?)
├── seatsaeroAPI/             # SeatsAero API integration (?)
├── .serena/                  # Serena MCP configuration
├── .claude/                  # Claude Code configuration
└── README.md                 # Project documentation
```

## FlightApp/ Main Directory

### Core App Files
- `FlightAppApp.swift` - App entry point with @main
- `ContentView.swift` - Root content view
- `Info.plist` - App configuration
- `FlightApp.entitlements` - App capabilities

### ViewModels/ (MVVM Architecture)
- `FlightViewModel.swift` - Flight detail view logic
- `RouteViewModel.swift` - Route view logic

### Models/Flights/
- `AeroFlight.swift` - Flight data models from AeroAPI
- `FlightTime.swift` - Time/date formatting models

### Views/ (Organized by feature)

#### Views/Search/
- `FlightSearchView_Redesigned.swift` - Hero search experience (current active design)
- `FlightSearchView.swift` - [Deleted in current branch]
- `FlightSearchView_LiquidGlass.swift` - [Deleted in current branch]

#### Views/Flight/
- `FlightView.swift` - Main flight detail view
- `FlightHeroSection.swift` - Top hero section with flight number
- `FlightRouteCard.swift` - Route information card
- `FlightAircraftCard.swift` - Aircraft details card
- `FlightGateTerminalCard.swift` - Gate/terminal info card
- `FlightRouteMapView.swift` - Route map wrapper
- `FlightRouteMapKitView.swift` - MapKit integration
- `FlightSelectionCard.swift` - Flight selection from list
- `FlightStatusView.swift` - Status display
- `FlightStatusBadge.swift` - Status badge component
- `FlightTimeView.swift` - Time display component
- `FlightErrorView.swift` - Error state display
- `AirportView.swift` - Airport information
- `RouteInformationView.swift` - Route details
- `FlightDetailsSection.swift` - [Deleted in current branch]
- `FlightHeader.swift` - [Deleted in current branch]
- `FlightHeaderView.swift` - [Deleted in current branch]

#### Views/Route/
- `RouteView.swift` - Route visualization with map

#### Views/Airline/
- `AirlineProfileView.swift` - Airline branding display
- `AirlineProfile.swift` - Airline profile model/view
- `AirlineTheme.swift` - Airline theming support
- `CodeshareInformationView.swift` - Codeshare display

#### Views/Common/
- `GlassEffectContainer.swift` - Liquid glass effect wrapper
- `LoadingView.swift` - Loading state component
- `BottomActionBar.swift` - Bottom action bar

#### Views/Settings/
- `SettingsView.swift` - App settings

### Services/ (Business Logic & Data)

#### Core Services
- `AeroAPIService.swift` - FlightAware API client with caching
- `AeroAPICacheService.swift` - API response caching layer
- `SeatsAeroAPIService.swift` - SeatsAero API integration
- `RequestDeduplicator.swift` - Prevents duplicate requests

#### Data Services
- `WaypointDatabaseService.swift` - International waypoint lookup
- `AirportCoordinateService.swift` - Airport coordinate resolution
- `AircraftTypeService.swift` - Aircraft type information

#### Airline Services
- `AirlineService.swift` - Airline information
- `AirlineLogoService.swift` - Logo retrieval
- `AirlineColorService.swift` - Brand color management

#### Utility Services
- `HapticManager.swift` - Centralized haptic feedback with custom patterns
- `FeatureFlags.swift` - Feature toggle management
- `SearchInputParser.swift` - Search query parsing

#### Services/Stores/
- `PopularRouteStore.swift` - Featured/sample flights
- `RecentSearchStore.swift` - Search history

### Extensions/
- `Date+Formatting.swift` - Date formatting utilities

### Assets/
- `Assets.xcassets/` - App icons, colors, images
- `logos/` - Airline logo images (600+ PNG files for different airlines)

### Data Files
- `international_waypoints.csv` - 31,774+ waypoint database
- `complete_navigation_database.csv` - Full navigation data

### Configuration
- `Config-Template.xcconfig` - Template for API keys
- `.gitignore` - Git ignore rules

## Key Architectural Patterns

### MVVM Structure
- **Models**: `Models/Flights/` - Data structures
- **Views**: `Views/` - SwiftUI views organized by feature
- **ViewModels**: `ViewModels/` - Business logic and state management

### Service Layer
All external dependencies and business logic isolated in `Services/`
- API clients, caching, data transformation
- Shared state stores
- Utility managers (haptics, feature flags)

### View Organization
Views are organized by feature/domain:
- Search experience
- Flight details
- Route visualization
- Airline branding
- Common/reusable components

## Recent Structural Changes (Current Branch)
Based on git status, recent deletions include:
- Old search view implementations (consolidated to _Redesigned version)
- Old flight header components (consolidated into FlightHeroSection)
- FlightDetailsSection (likely refactored into specialized cards)

New additions:
- `AeroAPICacheService.swift` - Caching layer
- `AirlineColorService.swift` - Brand color system
- `RequestDeduplicator.swift` - Request optimization
