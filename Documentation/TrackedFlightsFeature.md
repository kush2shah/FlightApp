# Tracked Flights Feature

## Overview
A new feature that allows users to track flights with a beautiful map visualization showing great circle paths of all tracked routes. The implementation follows the existing FlightApp architecture and design patterns.

## What Was Built

### 1. Data Layer (`TrackedFlightsStore.swift`)
**Location:** `FlightApp/Services/Stores/TrackedFlightsStore.swift`

**Features:**
- `TrackedFlight` model with comprehensive flight metadata
- Persistent storage using `UserDefaults` (follows pattern from `RecentSearchStore`)
- Support for pinning important flights
- Conversion from `AeroFlight` API responses
- Active/completed flight filtering
- Maximum 50 tracked flights with automatic cleanup

**Key Methods:**
- `addFlight(_:)` - Add a flight to tracking
- `removeFlight(_:)` - Remove from tracking
- `togglePin(for:)` - Pin/unpin flights
- `isTracking(flightNumber:)` - Check if flight is tracked

### 2. Map Visualization (`TrackedFlightsMapView.swift`)
**Location:** `FlightApp/Views/Flight/TrackedFlightsMapView.swift`

**Features:**
- MapKit integration showing all tracked flights
- Great circle path calculation and rendering
- Beautiful gradient paths with dashed styling
- Automatic map region calculation to fit all flights
- Green dots for origin airports, red dots for destinations
- Custom `GreatCirclePath` shape using proper geodesic calculations

**Algorithm:**
- Uses spherical trigonometry for accurate great circle paths
- 100 interpolation points per route for smooth curves
- Dynamic coordinate-to-screen conversion

### 3. Main UI (`TrackedFlightsView.swift`)
**Location:** `FlightApp/Views/Flight/TrackedFlightsView.swift`

**Features:**
- Map as background with tracked flight paths
- Scrollable list of tracked flights with glass effect cards
- Empty state with helpful messaging
- Filter tabs (All/Active)
- Flight count badges
- Rich flight cards showing:
  - Flight number
  - Origin → Destination with city names
  - Status with color-coded indicators
  - Progress percentage (for active flights)
  - Scheduled times
  - Airline name
  - Pin and remove buttons

**User Actions:**
- Tap card → Opens full flight details
- Pin button → Keeps flight at top
- Remove button → Untrack flight
- Swipe gestures with spring animations

### 4. Integration Points

#### FlightView (`FlightView.swift`)
**Added:**
- Star button in toolbar (yellow when tracked)
- `TrackedFlightsStore` integration
- `toggleTracking()` method with haptic feedback
- Support for `originCode` and `destinationCode` parameters

#### FlightSearchView (`FlightSearchView.swift`)
**Added:**
- Star icon button in trailing toolbar
- Full-screen cover for `TrackedFlightsView`
- Haptic feedback on open/close

## User Flow

### Adding a Flight to Tracking:
1. Search for and view a flight
2. Tap the star icon in the top-right toolbar
3. Success haptic feedback
4. Star turns yellow to indicate tracked status

### Viewing Tracked Flights:
1. From search view, tap the yellow star icon in the top-right
2. See map with great circle paths
3. Scroll through tracked flight cards
4. Tap any flight to view full details
5. Tap "Done" to return to search

### Managing Tracked Flights:
- **Pin:** Tap pin icon to keep flight at top of list
- **Unpin:** Tap filled pin icon to unpin
- **Remove:** Tap X button to stop tracking
- **View Details:** Tap anywhere on card

## Design Patterns Used

### Architecture:
- ✅ MVVM pattern (Store = Model layer)
- ✅ SwiftUI declarative UI
- ✅ `@StateObject` for store ownership
- ✅ Codable for persistence

### UI/UX:
- ✅ Liquid glass effect containers (consistent with app design)
- ✅ Haptic feedback for all interactions
- ✅ Spring animations for state changes
- ✅ Color-coded status indicators
- ✅ Full-screen cover for immersive experience
- ✅ Empty states with clear CTAs

### Code Quality:
- ✅ Separation of concerns (Store/View/Map)
- ✅ Reusable components (`TrackedFlightCard`, `FilterTab`)
- ✅ Type-safe model definitions
- ✅ Proper SwiftUI lifecycle management
- ✅ Preview support for development

## Technical Details

### Great Circle Path Mathematics:
The `GreatCirclePath` shape uses the **spherical law of cosines** to calculate intermediate points along the shortest path between two points on Earth:

```swift
// Calculate angular distance
d = 2 * asin(sqrt(sin²((lat1-lat2)/2) + cos(lat1)*cos(lat2)*sin²((lon1-lon2)/2)))

// Interpolate along path
a = sin((1-f)*d) / sin(d)
b = sin(f*d) / sin(d)

x = a*cos(lat1)*cos(lon1) + b*cos(lat2)*cos(lon2)
y = a*cos(lat1)*sin(lon1) + b*cos(lat2)*sin(lon2)
z = a*sin(lat1) + b*sin(lat2)

lat = atan2(z, sqrt(x²+y²))
lon = atan2(y, x)
```

This produces accurate geodesic paths that curve naturally on a spherical Earth projection.

### Persistence Strategy:
- Uses `UserDefaults` for lightweight storage (< 50 flights)
- JSON encoding/decoding via `Codable`
- Automatic save on all mutations
- Lazy loading on store initialization

### Performance Considerations:
- Map region calculation only on flight list changes
- Lazy loading of flight cards with `LazyVStack`
- Efficient filtering using Swift's native array methods
- Great circle paths cached per render cycle

## Future Enhancements

Potential improvements for the feature:

1. **Background Refresh**
   - Periodically update flight status for active flights
   - Push notifications for status changes

2. **Enhanced Filtering**
   - Filter by airline
   - Filter by route
   - Sort by date/status/progress

3. **Map Interactions**
   - Tap on route path to highlight flight
   - Zoom to individual flight
   - Show aircraft position on active flights

4. **Analytics**
   - Track total flights tracked
   - Most tracked routes
   - Flight history over time

5. **Sharing**
   - Share tracked flight status
   - Export flight list

6. **Widgets**
   - Home screen widget showing next active flight
   - Lock screen widget for flight progress

## Files Added

```
FlightApp/
├── Services/
│   └── Stores/
│       └── TrackedFlightsStore.swift          (New)
└── Views/
    └── Flight/
        ├── TrackedFlightsView.swift           (New)
        └── TrackedFlightsMapView.swift        (New)
```

## Files Modified

```
FlightApp/Views/
├── Flight/
│   └── FlightView.swift                       (Modified)
└── Search/
    └── FlightSearchView.swift                 (Modified)
```

## Testing Checklist

- [ ] Add a flight from FlightView
- [ ] Verify persistence across app restarts
- [ ] Remove a flight from tracked list
- [ ] Pin/unpin flights
- [ ] View flight details from tracked list
- [ ] Test with 0 flights (empty state)
- [ ] Test with multiple flights (map paths)
- [ ] Test great circle paths across date line
- [ ] Verify haptic feedback
- [ ] Test on different screen sizes

## Dependencies

- **MapKit** - Map rendering and coordinate systems
- **SwiftUI** - UI framework
- **Foundation** - UserDefaults, Codable, Date handling
- Existing services:
  - `HapticManager` - Haptic feedback
  - `AeroFlight` model - Flight data structure
  - `GlassEffectContainer` - UI styling

---

**Created:** November 2, 2025
**Status:** ⚠️ Hidden Behind Feature Flag

## Feature Flag Status

The tracked flights feature is currently **disabled by default** and hidden behind a feature flag:

```swift
FeatureFlags.shared.canUseTrackedFlights // default: false
```

To enable in Settings or programmatically:
```swift
FeatureFlags.shared.isTrackedFlightsEnabled = true
```

When disabled:
- Star button in FlightView toolbar is hidden
- Star button in FlightSearchView toolbar is hidden
- TrackedFlightsView cannot be accessed

This allows for safe deployment while the feature is being refined and tested.
