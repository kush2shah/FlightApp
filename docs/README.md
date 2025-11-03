# FlightApp ✈️

A personal iOS flight tracking app built with SwiftUI that combines real-time flight data, award availability, and cash price comparison.

## About

FlightApp started as a passion project combining my love for travel and curiosity around data. I wanted to create something that could use available real-world flight data and present it in an interface designed using feedback I'd have for another app.

This project serves multiple learning goals:
- **iOS Development**: Hands-on experience with Swift/SwiftUI and industry-grade APIs
- **AI-Assisted Development**: Exploring how AI tools can accelerate prototype development and code refinement
- **Industry API Integration**: Working with FlightAware's AeroAPI, Amadeus API, and Seats.aero
- **App Store Connect**: Taking a project from concept to App Store submission solo
- **Prioritization**: Working on prioritizing what's important so the product can get into people's hands asap

*Note: This is a snapshot-in-time personal project. Features and functionality may evolve or change over time as I continue learning and experimenting.*

## Features

### Flight Tracking
- **Real-time Flight Tracking**: Live flight status, departure/arrival times, and progress tracking
- **Interactive Route Maps**: Visual flight paths with waypoints using MapKit
- **Comprehensive Flight Details**: Aircraft information, airports, delays, and more
- **International Waypoint Database**: 31,774+ waypoints with ARINC 424 support for accurate route visualization

### Route Intelligence
- **Route Visualization**: Enhanced mapping with VOR/DME/NDB navigation points
- **Current Flights**: See what flights are currently operating on a route
- **Award Availability**: Integration with Seats.aero for mileage redemption options
- **Cash Price Comparison**: Amadeus API integration for comparing cash vs. award prices

### Search Experience
- **Unified Search Bar**: Search by flight number or route with intelligent airport matching
- **Airport Search**: Fuzzy search across IATA codes, ICAO codes, city names, and airport names
- **Smart Suggestions**: Context-aware suggestions including popular airports and destinations
- **Liquid Glass Design**: Premium glass morphism effects with haptic feedback throughout

## Technical Stack

- **iOS**: SwiftUI, MapKit, Combine
- **APIs**:
  - FlightAware AeroAPI for real-time flight data
  - Amadeus Self-Service API for cash flight prices
  - Seats.aero API for award availability
- **Data**: Navigation database with international waypoints, airport coordinates
- **Architecture**: MVVM pattern with async/await
- **Design System**: Liquid glass aesthetic with airline branding and haptic feedback
- **Development**: Claude was used as a peer in building this

## Current Status

**Branch**: `route-visibility`
**Main Branch**: `main`

### Recent Developments

#### ✅ Amadeus Cash Price Integration
- Implemented Amadeus API service with OAuth2 authentication
- Created FlightOffer data models for pricing information
- Added CashPriceCard component to display flight options
- Integrated cash prices into RouteView alongside award availability
- Implemented request caching and rate limiting

#### ✅ Liquid Glass Route Search
- Unified search bar supporting both flight numbers and routes
- Intelligent airport search with fuzzy matching and smart ranking
- Context-aware suggestions (popular airports, popular destinations from selected origin)
- Smooth animations and haptic feedback patterns
- Flag emojis for instant country recognition

#### ✅ Enhanced Route Experience
- Comprehensive route information with IFR routes, current flights, and awards
- Side-by-side comparison of cash prices vs. award availability
- Interactive maps with great circle routes
- Airline branding throughout the experience

### Key Services
- **AeroAPIService**: Flight data fetching with caching
- **AmadeusAPIService**: Cash flight price searches
- **SeatsAeroAPIService**: Award availability lookup
- **AirportSearchService**: Intelligent airport search and suggestions
- **WaypointDatabaseService**: International waypoint resolution
- **HapticManager**: Centralized haptic feedback patterns

### Data Models
- **AeroFlight**: FlightAware API response with null-safety
- **FlightOffer**: Amadeus pricing and itinerary data
- **Airport**: Rich airport model with coordinates and metadata
- **FlightTime**: Advanced time/date formatting with timezone support
- **WaypointData**: Comprehensive navigation database entries

### UI Components
- **FlightSearchView**: Hero search experience with UnifiedSearchBar
- **FlightView**: Detailed flight information with route mapping
- **RouteView**: Route visualization with cash prices, awards, and current flights
- **CashPriceCard**: Clean display of flight options with pricing
- **GlassEffectContainer**: Reusable liquid glass styling

## Development Setup

### API Credentials Required
You'll need API keys from:
1. **FlightAware AeroAPI** - Real-time flight data
2. **Amadeus Self-Service API** - Cash flight prices (test & production keys)
3. **Seats.aero API** - Award availability

Add these to `Config.xcconfig` (use `Config-Template.xcconfig` as a guide).

### Testing Flights (Verified Working)
- **AA1** (JFK-LAX) - Featured domestic route
- **UA60** (SFO-MEL) - Long-haul international with transpacific routing
- **BA175** (LHR-JFK) - Reliable transatlantic service

### Testing Routes (Verified Working)
- **JFK → LHR** - Popular transatlantic route
- **SFO → NRT** - Transpacific route
- **LAX → SYD** - Long-haul route with award availability

## Architecture Highlights

### Async Data Loading
All route data loads in parallel without blocking:
- IFR routes
- Current flights
- Award availability
- Cash prices

Each service operates independently with proper error handling.

### Caching Strategy
- **API Response Caching**: 1-hour TTL for Amadeus and Seats.aero
- **Request Deduplication**: Prevents duplicate simultaneous requests
- **Token Caching**: OAuth2 tokens cached until expiration

### Error Handling Philosophy
- Cash prices and awards are nice-to-have, not required
- Failures don't break core flight tracking functionality
- User sees friendly error states
- Detailed logging for debugging

## Design Philosophy

This app follows a liquid glass design language:

1. **Liquid Glass**: Smooth glass morphism effects throughout
2. **Haptic Feedback**: Aggressive, experience-defining patterns (click, forming, breaking, impact)
3. **Airline Branding**: Colors and logos integrated contextually
4. **Context-Aware**: Intelligent suggestions based on user state
5. **Minimal Friction**: Inline experiences, no unnecessary modals
6. **Delightful Details**: Flag emojis, smooth animations, satisfying interactions

## Privacy & Terms

FlightApp respects user privacy and only collects necessary flight data for functionality. See [Privacy Policy](https://kushs.org/app-privacy) and [Terms and Conditions](https://kushs.org/app-terms) for details.

## Contact

Email: hello@kushs.org

---

*This app is not affiliated with any airline or aviation authority. Flight data is provided by FlightAware's AeroAPI, Amadeus, and Seats.aero for informational purposes only.*
