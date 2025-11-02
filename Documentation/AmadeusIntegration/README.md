# Amadeus API Integration Documentation

## Overview
This folder contains comprehensive design documentation for integrating the Amadeus Self-Service API into FlightApp to enable cash price comparison alongside award availability.

## Documentation Structure

### 1. [Architecture Overview](./01-architecture-overview.md)
High-level system architecture showing how Amadeus API integrates with existing FlightApp components.

### 2. [API Service Design](./02-api-service-design.md)
Detailed design for `AmadeusAPIService` including authentication, endpoints, caching, and error handling.

### 3. [Data Models](./03-data-models.md)
Complete data model definitions for Amadeus responses, including `FlightOffer`, `PriceMetrics`, and comparison models.

### 4. [UI Integration](./04-ui-integration.md)
UI component designs, layout specifications, and user flow for displaying cash prices and value comparisons.

### 5. [Feature Flags & Settings](./05-feature-flags-settings.md)
Configuration management for Amadeus features, including test/production switching and user preferences.

### 6. [Implementation Phases](./06-implementation-phases.md)
Step-by-step implementation plan with milestones, dependencies, and testing strategies.

### 7. [API Usage & Cost Management](./07-api-usage-cost.md)
Rate limiting, caching strategies, and cost optimization techniques for Amadeus API calls.

## Quick Start

### Phase 1: Basic Integration (Start Here)
1. Create `AmadeusAPIService.swift` - see [02-api-service-design.md](./02-api-service-design.md)
2. Create data models - see [03-data-models.md](./03-data-models.md)
3. Add feature flag - see [05-feature-flags-settings.md](./05-feature-flags-settings.md)
4. Simple UI display - see [04-ui-integration.md](./04-ui-integration.md#phase-1-basic-display)

### Current Status
- **Credentials**: ✅ Available in `Config.xcconfig`
- **API Service**: ⏳ Not yet implemented
- **Data Models**: ⏳ Not yet implemented
- **UI Components**: ⏳ Not yet implemented
- **Feature Flags**: ⏳ Not yet implemented

## Goals

### Primary Goal
Enable users to compare cash flight prices (via Amadeus) against award availability (via Seats.aero) to make informed booking decisions.

### Success Metrics
1. Users can see cash prices for routes where awards are available
2. Value-per-point calculation helps users choose cash vs. miles
3. Price data loads without blocking existing flight/award data
4. API costs remain under budget through effective caching

## Related Code Locations

- **Existing Award Implementation**: `FlightApp/Views/Route/RouteView.swift` (lines 191-217)
- **Award Data Service**: `FlightApp/Services/SeatsAeroAPIService.swift`
- **Route ViewModel**: `FlightApp/ViewModels/RouteViewModel.swift`
- **Feature Flags**: `FlightApp/Services/FeatureFlags.swift`
- **Settings UI**: `FlightApp/Views/Settings/SettingsView.swift`
- **API Credentials**: `FlightApp/Config.xcconfig` (lines 13-16)

## External Resources

- [Amadeus Self-Service API Documentation](https://developers.amadeus.com/)
- [Amadeus Python SDK Reference](https://github.com/amadeus4dev/amadeus-python)
- [Flight Offers Search API](https://developers.amadeus.com/self-service/category/flights/api-doc/flight-offers-search)
- [Price Analytics API](https://developers.amadeus.com/self-service/category/flights/api-doc/flight-price-analysis)

## Notes

- **Test vs Production**: Start with test API (free tier, 10k requests/month) before switching to production
- **Caching Required**: Amadeus API charges per request - aggressive caching is essential
- **Async Design**: All API calls must be async/await to avoid blocking UI
- **Error Handling**: Cash prices are nice-to-have; failures should not break award display
