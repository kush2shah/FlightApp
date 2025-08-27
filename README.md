# FlightApp ✈️

A personal iOS flight tracking app built with SwiftUI and FlightAware's AeroAPI.

## About

FlightApp started as a passion project combining my love for travel and curiosity around data. I wanted to create something that could use available real-world flight data and present it in an interface designed using feedback I'd have for another app.

This project serves multiple learning goals:
- **iOS Development**: Hands-on experience with Swift/SwiftUI and industry-grade APIs
- **AI-Assisted Development**: Exploring how AI tools can accelerate prototype development and code refinement
- **Industry API Integration**: Working with FlightAware's AeroAPI to understand real-world data patterns
- **App Store Connect**: Taking a project from concept to App Store submission solo
- **Prioritization**: Working on prioritzing what's important so the product can get into people's hands asap

*Note: This is a snapshot-in-time personal project. Features and functionality may evolve or change over time as I continue learning and experimenting.*

## Features

- **Real-time Flight Tracking**: Live flight status, departure/arrival times, and progress tracking
- **Interactive Route Maps**: Visual flight paths with waypoints using MapKit
- **Comprehensive Flight Details**: Aircraft information, airports, delays, and more
- **Route Visualization**: Enhanced mapping with VOR/DME/NDB navigation points

## Technical Stack

- **iOS**: SwiftUI, MapKit, Combine
- **API**: FlightAware AeroAPI for real-time flight data
- **Data**: Navigation database with international waypoints
- **Architecture**: MVVM pattern with async/await
- **Development**: Claude was used as a peer in building this

## Development History & Current Status

### Enhanced Home Screen & Search Experience (Current Branch: `map-centric-search`)

**Goal**: Transform the app into a search-centric experience where the search bar is the hero element, making flight discovery addictive and engaging.

#### ✅ Completed Work

1. **Hero Search Bar Implementation**
   - Redesigned FlightSearchView with centered, prominent search bar
   - Added large typography ("Track Any Flight" title)
   - Implemented focus animations and visual feedback
   - Added clear button and enhanced search field styling

2. **UI/UX Improvements**
   - Moved popular routes to subtle overflow menu with SF Symbols
   - Clean gradient background design
   - Reduced visual clutter to focus on search
   - Added search hint buttons (AA1, UA60, BA175)

3. **Critical Bug Fixes**
   - **Oceanic coordinate parsing**: Fixed DDMM format parsing crash
     - `0649N08043E` now correctly parsed as `6.816°N, 80.716°E`
     - Prevents MapKit "Invalid Region" crashes
   - **Flight date filtering**: Fixed random historical dates issue
     - Added `start` parameter to AeroAPI calls for current/upcoming flights only
   - **Search messaging**: Updated UI to reflect actual capabilities (flight numbers only)

#### 🔄 Current Status

**Branch**: `map-centric-search`  
**Last Commit**: `828c8fb` - Fix flight date filtering  

**What Works**:
- Hero search bar with animations and focus states
- Popular routes accessible via overflow menu (ellipsis icon)
- Coordinate parsing fixed (no more app crashes)
- Date filtering shows relevant flights only
- Enhanced visual design with gradients and shadows

#### 📋 Next Steps (Pending Implementation)

1. **Enhanced Search Experience**
   - Real-time search suggestions as user types
   - Search history integration with better UX
   - Haptic feedback on search interactions

2. **Advanced Search Animations**
   - Smooth focus/unfocus transitions  
   - Premium loading state animations
   - Enhanced visual feedback systems

3. **Map Background Integration** (Future Vision)
   - Replace current background with interactive world map
   - Floating search bar overlay on map
   - Search → map zoom → route trace → detail overlay flow
   - "Commanding a global view" user experience

### Previous Major Development

#### International Route Tracking System (`enhanced-route-mapping` branch)
- Comprehensive ARINC 424 waypoint database (31,774+ waypoints)
- Complex oceanic coordinate parsing for international flights
- Advanced route string parsing for multi-waypoint paths
- Enhanced MapKit integration with custom annotations

#### Navigation Database Integration
- CSV-based waypoint loading with fallback mechanisms
- Support for VOR, DME, NDB navigation aids
- Geographic coordinate validation and error handling
- Real-time waypoint resolution for flight routes

## Technical Architecture

### Key Services
- **AeroAPIService**: Flight data fetching with proper date filtering
- **WaypointDatabaseService**: International waypoint resolution with coordinate fixes
- **PopularRouteStore**: Sample flight management with featured routes

### Enhanced Data Models  
- **AeroFlight**: FlightAware API response with null-safety
- **FlightTime**: Advanced time/date formatting with timezone support
- **WaypointData**: Comprehensive navigation database entries

### Current UI Focus
- **FlightSearchView**: Hero search experience (heavily redesigned)
- **FlightView**: Detailed flight information with route mapping
- **FlightRouteMapKitView**: Enhanced route visualization

## Search-First Design Philosophy

The current development direction focuses on making search the primary, addictive interaction:
- Large, centered search bar as the hero element
- Minimal visual distractions to maintain focus
- Quick access to sample flights without visual competition
- Smooth animations that encourage repeated engagement

### Future Vision: Map-Centric Experience
Planned evolution toward a unique map-integrated experience:
1. World map as primary background
2. Floating search interface over interactive map
3. Seamless search → map zoom → route trace → detail overlay
4. Users feel like they're "commanding a global view" of aviation

## Development Setup

### Testing Flights (Verified Working)
- **AA1** (JFK-LAX) - Featured domestic route
- **UA60** (SFO-MEL) - Long-haul international
- **BA175** (LHR-JFK) - Reliable transatlantic service

### Key Modified Files
- `FlightSearchView.swift` - Complete hero search redesign
- `AeroAPIService.swift` - Enhanced with proper date filtering  
- `WaypointDatabaseService.swift` - Critical coordinate parsing fixes applied
- `PopularRouteStore.swift` - Sample flights with featured route system

## Known Limitations & Next Session Goals

**Current Limitations**:
- Search supports flight numbers only (airports/airlines not implemented)
- Map background integration pending
- Real-time search suggestions not yet added

**When Resuming Development**:
1. Continue with pending todos for enhanced search experience
2. Begin map background integration work
3. Implement search-to-map transition animations
4. Add real-time search suggestions and autocomplete

The foundation for a search-centric, map-integrated flight tracking experience is now solidly in place, with critical bugs resolved and a clear path forward.

## Development Philosophy

This project represents an exploration of modern development workflows, particularly the role of AI in rapid prototyping and iteration. The goal was to see how quickly a functional, polished app could be built by combining domain knowledge, AI assistance, and traditional development practices.

### Key Learnings

- Working with real-time aviation data and industry APIs
- MapKit integration and custom geospatial visualization
- SwiftUI state management and async operations
- AI-assisted debugging and feature development
- Asset management and App Store Connect process

## Privacy & Terms

FlightApp respects user privacy and only collects necessary flight data for functionality. See [Privacy Policy](https://kushs.org/app-privacy) and [Terms and Conditions](https://kushs.org/app-terms) for details.

## Contact
 
Email: hello@kushs.org

---

*This app is def not affiliated with any airline or aviation authority. Flight data is provided by FlightAware's AeroAPI for informational purposes only.*
