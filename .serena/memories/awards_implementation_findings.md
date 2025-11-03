# FlightApp Awards Section Implementation Analysis

## 1. CURRENT AWARDS SECTION IMPLEMENTATION

### Award Display Implementation
**Location**: `/Users/kush/Developer/FlightApp/FlightApp/Views/Route/RouteView.swift`

**Award Availability Section** (lines 191-217):
- Section titled "Award Availability" with star icon
- Displays up to 20 award results with "Showing first 20 results" message if more exist
- Uses `AwardRowCard` component for each award

**AwardRowCard Component** (lines 613-650):
- Shows: Calendar icon + formatted date, airline program name
- Displays: Best available cabin class, mileage cost (in points), remaining seats
- Conditionally renders only if cabin availability exists
- Styled with custom SF Rounded font

### Data Model
**Location**: `/Users/kush/Developer/FlightApp/FlightApp/Services/SeatsAeroAPIService.swift` (lines 175-237)

```swift
struct AwardAvailability: Codable, Identifiable {
    let id: String
    let routeID: String
    let date: String
    let source: String  // Mileage program name (e.g., "American AAdvantage")
    
    // Cabin availability (Y=Economy, W=Premium Economy, J=Business, F=First)
    let yAvailable: Bool?, yMileageCost: String?, yRemainingSeats: Int?
    let wAvailable: Bool?, wMileageCost: String?, wRemainingSeats: Int?
    let jAvailable: Bool?, jMileageCost: String?, jRemainingSeats: Int?
    let fAvailable: Bool?, fMileageCost: String?, fRemainingSeats: Int?
    
    // Method to get best available cabin (prioritizes F > J > W > Y)
    func bestAvailableCabin() -> (cabin: String, cost: String, seats: Int)?
}
```

### Award Loading Logic
**Location**: `/Users/kush/Developer/FlightApp/FlightApp/ViewModels/RouteViewModel.swift` (lines 108-138)

Process:
1. Checks if feature flag `FeatureFlags.shared.canUseSeatsAero` is enabled
2. Converts ICAO airport codes to IATA using `SearchInputParser.shared.icaoToIata()`
3. Searches next 30 days for award availability
4. Requests business & first class cabins specifically
5. Stores results in `@Published var awards: [AwardAvailability] = []`
6. Awards loading is optional - errors don't block flight loading

---

## 2. FLIGHT DATA MODELS

**Location**: `/Users/kush/Developer/FlightApp/FlightApp/Models/Flights/AeroFlight.swift`

Key flight properties:
- **Identifiers**: `ident`, `identIcao`, `identIata`, `flightNumber`, `faFlightId`
- **Routing**: `origin`, `destination`, `route`, `codeshares`, `codeshares_iata`
- **Aircraft**: `aircraftType`, `registration`
- **Status**: `status`, `cancelled`, `diverted`, `blocked`, `positionOnly`
- **Times**: `scheduledOut`, `estimatedOut`, `actualOut` (and similar for Off, On, In)
- **Progress**: `progressPercent`, `filedEte`, `routeDistance`
- **Gates/Terminals**: `gateOrigin`, `gateDestination`, `terminalOrigin`, `terminalDestination`
- **Delays**: `departureDelay`, `arrivalDelay`
- **Baggage**: `baggageClaim`
- **Metadata**: `links` (AeroLinks object from API)

Flight data fetched via `AeroAPIService.shared.searchFlight()` and stored in `FlightViewModel`.

---

## 3. BOOKING/EXTERNAL LINK FUNCTIONALITY

### Existing Links
1. **Airline Website Links** (`AirlineProfileView.swift`, lines 87-100):
   - Uses SwiftUI `Link(destination:)` component
   - Links to airline website from `airline.website` property
   - Shows "Visit Website" with arrow icon
   - Branded with airline colors using `brandedGlassEffect`

2. **Airline Information Service** (`AirlineService.swift`):
   - Fetches airline data from FlightAware AeroAPI
   - Properties include: `url`, `wiki_url`, `phone`, `country`, `location`
   - Maps to `AirlineProfile` model with `website` property

### No Direct Booking Integration
- NO booking links in flight details view
- NO direct links to purchase awards/miles
- NO integration with airline booking systems (Amadeus, Sabre, etc.)
- NO baggage claim tracking external links
- Award data from Seats.aero does not include booking links

---

## 4. CUSTOMIZATION & SETTINGS PATTERNS

### Feature Flags System
**Location**: `/Users/kush/Developer/FlightApp/FlightApp/Services/FeatureFlags.swift`

```swift
class FeatureFlags: ObservableObject {
    static let shared = FeatureFlags()
    
    @AppStorage("seatsAeroEnabled") var isSeatsAeroEnabled: Bool = true
    
    var canUseSeatsAero: Bool {
        isSeatsAeroEnabled
    }
}
```

### Settings UI
**Location**: `/Users/kush/Developer/FlightApp/FlightApp/Views/Settings/SettingsView.swift` (lines 11-57)

`SettingsButton` component in toolbar provides:
- **Haptic Intensity Menu**: Selects aggressive, balanced, or light feedback
  - Uses `@AppStorage("hapticIntensity")` to persist
  - Triggers haptic feedback on selection
  - Shows checkmark for current selection
- **Feature Toggles Section**: Toggle for "Award Search" (Seats.aero)
- **About Section**: Version info

Settings appear in a Menu (context menu) with Liquid Glass styling.

### Persistent Storage
- Uses `@AppStorage` for UserDefaults integration
- Keys: `"hapticIntensity"`, `"seatsAeroEnabled"`
- Automatic syncing with SwiftUI state

---

## 5. NAVIGATION & DEEP LINKING PATTERNS

### App Entry Point
**Location**: `/Users/kush/Developer/FlightApp/FlightApp/FlightAppApp.swift`

```swift
@main
struct FlightAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Root Navigation Flow
**ContentView.swift**: Single entry point → `FlightSearchView_Redesigned()`

### Navigation Stack Architecture

**Search View** (`FlightSearchView_Redesigned.swift`):
- Root: `NavigationStack`
- Displays: Search interface with recent flights & discover sections
- Sheet: `FlightSelectionSheet` for selecting from search results
- Navigation Link: Pushes to `FlightView` with selected flight

**Flight View** (`FlightView.swift`, lines 24-25):
- Takes parameters: `flightNumber: String`, `faFlightId: String?`, `skipFlightSelection: Bool`
- Uses nested `NavigationStack` for internal navigation
- Can navigate to: Route view (for route analysis)

**Route View** (`RouteView.swift`):
- Shows award availability, flights on route, route map
- Award cards don't currently link anywhere
- Can push to flight details

### State Management
- Uses `@StateObject` for view models
- Uses `@State` for local UI state
- Uses `@FocusState` for search focus
- Uses `@Namespace` for matched geometry animations
- Uses `@Environment(\.dismiss)` for navigation back

### No Deep Linking Implementation
- NO URL scheme handling
- NO universal links / app links
- NO passing flight data via URLs
- NO state restoration from deep links

---

## 6. ARCHITECTURE & INTEGRATION POINTS

### MVVM Structure
- **Models**: `AeroFlight`, `AwardAvailability`, `AirlineProfile`
- **ViewModels**: `FlightViewModel`, `RouteViewModel`
- **Views**: Organized by feature (Flight, Route, Search, Airline, Settings)
- **Services**: API clients, caching, data transformation

### Award Data Flow
1. User navigates to route view (from search)
2. `RouteViewModel.loadRouteData()` called with origin/destination
3. Parallel tasks:
   - `loadRouteInfo()` → IFR routes
   - `loadFlights()` → current flights
   - `loadAwards()` → award availability (via Seats.aero API)
4. Results bound to `@Published` properties
5. Views subscribe and render

### API Integration Points
- **FlightAware AeroAPI**: Flight tracking, routes, aircraft, airlines
- **Seats.aero API**: Award availability (business/first class focused)
- **Airport Coordinates Service**: Local JSON database of 31,774+ waypoints
- **Airline Service**: Airline information (logos, colors, URLs)

### No Booking Flow
- Views only display information
- No booking buttons or links in flight details
- Airline website link is only external action available
- Awards data viewed but not actionable

---

## KEY FINDINGS SUMMARY

1. **Awards fully integrated** into route view with Seats.aero API
2. **Feature flag controlled** - can be disabled in settings
3. **No booking integration** - awards shown for reference only
4. **External links pattern** exists (airline website) but minimal usage
5. **Settings pattern established** using @AppStorage & FeatureFlags singleton
6. **No deep linking** - navigation fully within-app with NavigationStack
7. **Service layer** isolated - easy to add new APIs without UI changes
8. **MVVM architecture** supports separation of concerns

---

## FUTURE EXTENSION POINTS

To add award booking functionality:
1. Add booking URLs to `AwardAvailability` model from Seats.aero API
2. Create `AwardBookingView` component with Link to airline's booking site
3. Add toggle in settings to enable booking links
4. Consider affiliate/partnership links for revenue
5. Add support for other award programs (AA, United, Delta, etc.) via API expansion
