# Architecture Overview

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          FlightApp UI Layer                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────┐         ┌──────────────────────┐           │
│  │ FlightView     │         │ RouteView            │           │
│  │                │────────▶│                      │           │
│  │ - Flight Info  │         │ - Route Map          │           │
│  └────────────────┘         │ - Award Availability │◀──┐       │
│                             │ - Cash Prices (NEW)  │   │       │
│                             └──────────────────────┘   │       │
│                                                         │       │
└─────────────────────────────────────────────────────────┼───────┘
                                                          │
┌─────────────────────────────────────────────────────────┼───────┐
│                       ViewModel Layer                   │       │
├─────────────────────────────────────────────────────────┼───────┤
│                                                         │       │
│  ┌────────────────┐         ┌──────────────────────┐   │       │
│  │ FlightViewModel│         │ RouteViewModel       │   │       │
│  │                │         │                      │   │       │
│  │ @Published     │         │ @Published           │   │       │
│  │ - flightData   │         │ - flights            │   │       │
│  └────────────────┘         │ - awards             │   │       │
│                             │ - cashOffers (NEW)   │───┘       │
│                             │ - priceMetrics (NEW) │           │
│                             └──────┬───────┬───────┘           │
│                                    │       │                   │
└────────────────────────────────────┼───────┼───────────────────┘
                                     │       │
┌────────────────────────────────────┼───────┼───────────────────┐
│                      Service Layer │       │                   │
├────────────────────────────────────┼───────┼───────────────────┤
│                                    ▼       ▼                   │
│  ┌──────────────────┐   ┌──────────────────────────────┐      │
│  │ AeroAPIService   │   │ SeatsAeroAPIService          │      │
│  │                  │   │                              │      │
│  │ - Flight Tracking│   │ - Award Availability Search  │      │
│  │ - Route Info     │   │ - Loyalty Program Data       │      │
│  │ - Aircraft Data  │   └──────────────────────────────┘      │
│  └──────────────────┘                                          │
│                                                                │
│  ┌──────────────────────────────────────────────────┐         │
│  │ AmadeusAPIService (NEW)                          │         │
│  │                                                  │         │
│  │ - OAuth2 Authentication                         │         │
│  │ - Flight Offers Search                          │         │
│  │ - Flight Pricing Details                        │         │
│  │ - Price Analytics & Metrics                     │         │
│  │ - Response Caching (1 hour TTL)                 │         │
│  └──────────────────────────────────────────────────┘         │
│                             │                                  │
│  ┌──────────────────────────┼──────────────────────┐          │
│  │ FeatureFlags             │                      │          │
│  │                          │                      │          │
│  │ - canUseSeatsAero       │                      │          │
│  │ - canUseAmadeus (NEW)   │                      │          │
│  │ - isAmadeusProduction   │                      │          │
│  └──────────────────────────┼──────────────────────┘          │
│                             │                                  │
└─────────────────────────────┼──────────────────────────────────┘
                              │
┌─────────────────────────────┼──────────────────────────────────┐
│                    External APIs                               │
├─────────────────────────────┼──────────────────────────────────┤
│                             ▼                                  │
│  ┌─────────────────────────────────────────────────┐          │
│  │ Amadeus Self-Service API                        │          │
│  │                                                 │          │
│  │ Test Environment:                               │          │
│  │ - https://test.api.amadeus.com                  │          │
│  │ - 10 req/sec, 10k req/month (free)              │          │
│  │                                                 │          │
│  │ Production Environment:                         │          │
│  │ - https://api.amadeus.com                       │          │
│  │ - Pay-as-you-go pricing                         │          │
│  │                                                 │          │
│  │ Endpoints Used:                                 │          │
│  │ - POST /v2/shopping/flight-offers               │          │
│  │ - POST /v1/shopping/flight-offers/pricing       │          │
│  │ - GET  /v1/analytics/itinerary-price-metrics    │          │
│  └─────────────────────────────────────────────────┘          │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. User Navigates to Route View
```
User searches flight
    ↓
FlightView displays result
    ↓
User taps "View Route" button
    ↓
RouteView appears with origin/destination
    ↓
RouteViewModel.loadRouteData() triggered
```

### 2. Parallel Data Loading
```swift
async withTaskGroup {
    // Existing tasks
    Task { loadRouteInfo() }      // IFR routes from AeroAPI
    Task { loadFlights() }         // Current flights from AeroAPI
    Task { loadAwards() }          // Award seats from Seats.aero

    // NEW tasks
    Task { loadCashOffers() }      // Cash prices from Amadeus
    Task { loadPriceMetrics() }    // Historical trends from Amadeus
}
```

### 3. Data Aggregation & Matching
```
RouteViewModel combines:
- awards: [AwardAvailability]        (Seats.aero)
- cashOffers: [FlightOffer]          (Amadeus)
- priceMetrics: PriceMetrics?        (Amadeus)

Creates:
- matchedOffers: [MatchedOffer]
  ├─ date: "2025-01-15"
  ├─ award: AwardAvailability?
  ├─ cashOffer: FlightOffer?
  └─ valueAnalysis: ValueAnalysis
```

### 4. UI Rendering
```
RouteView displays sections:

1. Route Map (existing)
2. Current Flights (existing)
3. Award Availability (existing)
4. Cash Prices (NEW)
   └─ Shows FlightOffer cards
5. Value Comparison (NEW)
   └─ Shows MatchedOffer cards with recommendations
```

## Component Responsibilities

### AmadeusAPIService
**Purpose**: Handle all Amadeus API communication

**Responsibilities**:
- OAuth2 token management (acquire, cache, refresh)
- HTTP request/response handling
- Rate limiting and retry logic
- Response caching (in-memory, 1 hour TTL)
- Error mapping to domain errors
- Test vs Production environment switching

**Dependencies**:
- `Config.xcconfig` for credentials
- `URLSession` for networking
- `FeatureFlags` for environment selection

**Public Interface**:
```swift
func searchFlightOffers(SearchParams) async throws -> [FlightOffer]
func getPricing(FlightOffer) async throws -> DetailedPricing
func getPriceMetrics(RouteParams) async throws -> PriceMetrics
```

### RouteViewModel
**Purpose**: Manage route view state and orchestrate data loading

**Existing Responsibilities**:
- Load route info, flights, awards
- Handle loading states and errors
- Expose @Published properties for UI binding

**New Responsibilities**:
- Load cash offers from Amadeus
- Load price metrics from Amadeus
- Match awards with cash offers by date
- Calculate value-per-point metrics
- Generate booking recommendations

**New Published Properties**:
```swift
@Published var cashOffers: [FlightOffer] = []
@Published var priceMetrics: PriceMetrics?
@Published var isLoadingCashPrices = false
@Published var cashPriceError: Error?
```

### RouteView
**Purpose**: Display route information and comparison data

**Existing Sections**:
- Route map with waypoints
- Current flights on route
- Award availability cards

**New Sections**:
- Cash price cards (simple display)
- Value comparison cards (advanced analysis)
- Price trend indicators
- Booking recommendations

## Integration Points

### 1. Configuration Layer
```
Config.xcconfig
├─ AMADEUS_TEST_KEY
├─ AMADEUS_TEST_SECRET
├─ AMADEUS_PROD_KEY
└─ AMADEUS_PROD_SECRET
    ↓
FeatureFlags.swift
├─ canUseAmadeus: Bool
├─ isAmadeusProduction: Bool
└─ amadeusMaxCacheDuration: TimeInterval
    ↓
AmadeusAPIService.swift
└─ Uses flags for environment selection
```

### 2. Data Layer
```
Amadeus API Response
    ↓
AmadeusAPIService decodes to FlightOffer
    ↓
RouteViewModel stores in @Published property
    ↓
RouteView subscribes and renders
```

### 3. Cache Layer
```
Request Parameters → Cache Key
    ↓
Check NSCache for existing response
    ↓
If miss: Make API call → Store in cache
    ↓
Return cached or fresh data
```

## Error Handling Strategy

### Graceful Degradation
```
Cash price loading fails
    ↓
Log error to console
    ↓
Show existing awards data
    ↓
Display "Prices unavailable" message
    ↓
App remains fully functional
```

### User Communication
- Loading state: Skeleton cards
- Success: Display prices
- Error: Subtle message, don't block UI
- No data: "No prices found for these dates"

## Performance Considerations

### Parallel Loading
- All API calls happen concurrently
- Cash prices don't block awards or flights
- UI updates as each data source completes

### Caching Strategy
- **In-Memory Cache**: NSCache with 1 hour TTL
- **Cache Key**: "\(origin)-\(destination)-\(date)-\(passengers)"
- **Eviction**: LRU (automatic via NSCache)
- **Invalidation**: Manual clear in settings

### Rate Limiting
- **Test API**: Max 10 req/sec
- **Strategy**: Debounce search inputs
- **Batch**: Combine multiple date searches
- **Queue**: Serial queue for API calls

## Security Considerations

### API Credentials
- Stored in `.xcconfig` (gitignored)
- Never exposed to UI layer
- Template file in repo for setup

### Data Privacy
- No PII sent to Amadeus
- Only airport codes and dates
- No user tracking or analytics

### Network Security
- HTTPS only (enforced by Amadeus)
- Certificate pinning (future enhancement)
- Token stored in-memory only (not persisted)

## Testing Strategy

### Unit Tests
- `AmadeusAPIService` response parsing
- Cache hit/miss logic
- Error handling paths
- Value calculation algorithms

### Integration Tests
- End-to-end API flow (test environment)
- Token refresh logic
- Rate limiting behavior

### UI Tests
- Cash price section displays
- Loading states render correctly
- Error states handled gracefully

### Manual Testing
- Compare prices with airline websites
- Verify value calculations are accurate
- Test with various route combinations
- Validate test vs production switching

## Future Enhancements

### Phase 2+
1. **Price Alerts**: Notify when prices drop
2. **Booking Links**: Deep link to airline sites
3. **Multi-Passenger**: Family/group pricing
4. **Baggage Fees**: Include in total cost
5. **Calendar View**: Month-view price grid
6. **Flexible Dates**: ±3 days price comparison
7. **Analytics**: Track user booking patterns
8. **Export**: Share price comparisons

### Long-term
1. **Machine Learning**: Predict best booking time
2. **Multi-Alliance**: Compare across alliances
3. **Award Booking**: Direct award booking flow
4. **Trip Builder**: Multi-city cash+award combos
