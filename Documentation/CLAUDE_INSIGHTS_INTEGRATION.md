# Claude Insights Integration Guide

## Overview

This integration adds Claude 4.5 Haiku-powered insights to FlightApp, providing users with factual, accurate information about routes, awards, destinations, aircraft, and flights.

## Architecture

### Components

1. **ClaudeAPIService** - Handles API communication with Anthropic
2. **ClaudePromptBuilder** - Creates context-specific, concise prompts
3. **InsightsCacheService** - Caches insights for 1 hour (hybrid approach)
4. **InsightsViewModel** - Manages state and orchestrates insight generation
5. **InsightCard** - SwiftUI component with liquid glass styling

### Design Principles

- **Concise Prompts**: Each insight type has a minimal system prompt (2-3 sentences) + focused user prompt
- **Hybrid Caching**: Shows cached insights immediately, generates on miss
- **Context-Aware**: Different prompts for different contexts (awards, routes, destinations, etc.)
- **Cost Efficient**: Uses Haiku model, limits to 150 tokens, caches aggressively

## Setup

### 1. Add API Key to Build Configuration

Add your Anthropic API key to your build configuration file:

```bash
# In your Config.xcconfig file (not committed to git)
ANTHROPIC_KEY = sk-ant-api03-...your-key-here...
```

The key is already configured in `Info.plist`:
```xml
<key>ANTHROPIC_KEY</key>
<string>$(ANTHROPIC_KEY)</string>
```

### 2. Add Files to Xcode Project

Ensure all new files are added to your Xcode project:

**Services:**
- `ClaudeAPIService.swift`
- `ClaudePromptBuilder.swift`
- `InsightsCacheService.swift`

**ViewModels:**
- `InsightsViewModel.swift`

**Views/Common:**
- `InsightCard.swift`

## Integration Examples

### Example 1: Award Analysis in RouteView

Add award insights to the RouteView when displaying award availability:

```swift
// In RouteView.swift

import SwiftUI

struct RouteView: View {
    let route: Route
    @State private var awardData: [AwardOffer] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Existing route map
                RouteMapSection(route: route)

                // Award availability section
                if !awardData.isEmpty {
                    // Award cards...

                    // Add Claude insights
                    InsightCard(
                        type: .awardAnalysis,
                        context: InsightContext(
                            awardData: awardData,
                            origin: route.origin,
                            destination: route.destination
                        ),
                        airlineColors: AirlineColorService.shared.getBrandColors(for: route.airline)
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}
```

### Example 2: Destination Info in FlightView

Add destination insights when viewing a flight:

```swift
// In FlightView.swift

struct FlightView: View {
    let flight: AeroFlight

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Flight hero section
                FlightHeroSection(flight: flight)

                // Route card
                FlightRouteCard(flight: flight)

                // Add destination insights
                InsightCard(
                    type: .destination,
                    context: InsightContext(
                        destinationAirport: flight.destination.code,
                        destinationCity: flight.destination.city
                    ),
                    airlineColors: AirlineColorService.shared.getBrandColors(for: flight.airline)
                )
                .padding(.horizontal)

                // Aircraft insights
                if let aircraftType = flight.aircraft?.type {
                    InsightCard(
                        type: .aircraft,
                        context: InsightContext(
                            flightNumber: flight.flightNumber,
                            airline: flight.airline,
                            aircraftType: aircraftType
                        ),
                        airlineColors: AirlineColorService.shared.getBrandColors(for: flight.airline)
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}
```

### Example 3: Route Context in Search Results

Add route context when displaying search results:

```swift
// In a search results view

ForEach(searchResults) { result in
    VStack(spacing: 12) {
        // Search result card
        SearchResultCard(result: result)

        // Route context insight
        InsightCard(
            type: .routeContext,
            context: InsightContext(
                origin: result.origin,
                destination: result.destination,
                distance: result.distance,
                duration: result.duration
            ),
            airlineColors: nil
        )
    }
}
```

## Insight Types

### 1. Award Analysis (`.awardAnalysis`)

**When to use:** Viewing routes with award availability

**Required context:**
- `awardData: [AwardOffer]` - Array of award offers with program, miles, cabin
- `origin: String` - Origin airport code
- `destination: String` - Destination airport code

**Example output:**
> "This route shows business class availability through two Star Alliance partners: United MileagePlus at 70,000 miles and Virgin Atlantic Flying Club at 50,000 miles. Virgin Atlantic requires 20,000 fewer miles for this JFK-LHR routing in business class."

### 2. Destination (`.destination`)

**When to use:** Viewing flights to a specific destination

**Required context:**
- `destinationAirport: String` - Airport code (e.g., "SFO")
- `destinationCity: String` - City name (e.g., "San Francisco")

**Example output:**
> "This flight arrives at San Francisco International Airport (SFO), located 13 miles south of downtown San Francisco. The city is in the Pacific Time Zone, 3 hours behind Eastern Time."

### 3. Route Context (`.routeContext`)

**When to use:** Viewing route information or maps

**Required context:**
- `origin: String` - Origin airport code
- `destination: String` - Destination airport code
- `distance: Double` - Route distance in miles (optional)
- `duration: TimeInterval` - Flight duration (optional)

**Example output:**
> "This 7,488-mile transpacific route crosses the Pacific Ocean from Los Angeles to Sydney, Australia. The approximately 15-hour flight path crosses the International Date Line."

### 4. Aircraft (`.aircraft`)

**When to use:** Viewing flight details with aircraft information

**Required context:**
- `aircraftType: String` - Aircraft type (e.g., "Boeing 777-300ER")
- `airline: String` - Airline name
- `flightNumber: String` - Flight number (optional)

**Example output:**
> "This flight operates on a Boeing 777-300ER, a wide-body long-haul aircraft. United Airlines is a member of the Star Alliance."

### 5. Flight Status (`.flightStatus`)

**When to use:** Viewing real-time flight tracking

**Required context:**
- `flightNumber: String` - Flight number
- `origin: String` - Origin airport code
- `destination: String` - Destination airport code
- `departureTime: Date` - Scheduled departure (optional)
- `arrivalTime: Date` - Scheduled arrival (optional)

**Example output:**
> "Flight UA60 connects Newark with Los Angeles, crossing the continental United States. The approximately 5h 30m westbound flight benefits from favorable tailwinds."

## Data Models

### AwardOffer

```swift
struct AwardOffer {
    let program: String      // e.g., "United MileagePlus"
    let miles: Int          // e.g., 70000
    let cabin: String       // e.g., "Business"
}
```

### InsightContext

```swift
struct InsightContext {
    // Award context
    var awardData: [AwardOffer]?

    // Route context
    var origin: String?
    var destination: String?
    var distance: Double?
    var duration: TimeInterval?

    // Flight context
    var flightNumber: String?
    var airline: String?
    var aircraftType: String?
    var departureTime: Date?
    var arrivalTime: Date?

    // Destination context
    var destinationAirport: String?
    var destinationCity: String?
}
```

## Customization

### Adjusting Cache Duration

Edit `InsightsCacheService.swift`:

```swift
private let cacheDuration: TimeInterval = 3600 // 1 hour (default)
// Change to:
private let cacheDuration: TimeInterval = 7200 // 2 hours
```

### Adjusting Token Limit

Edit `ClaudeAPIService.swift`:

```swift
private let maxTokens = 150 // Default
// Increase for longer responses:
private let maxTokens = 250
```

### Modifying System Prompts

Edit `ClaudePromptBuilder.swift` to adjust the rules for each insight type. Keep prompts concise to minimize costs.

### Styling the Card

The `InsightCard` uses the existing liquid glass design system. To customize:

```swift
// Change corner radius
.background(
    RoundedRectangle(cornerRadius: 20) // Adjust here
)

// Change color intensity
.fill(airlineColors?.color.opacity(0.15)) // Adjust opacity
```

## Performance Considerations

### Caching Strategy

- **First view**: Generates insight (Claude API call)
- **Subsequent views**: Shows cached insight instantly
- **After 1 hour**: Auto-refreshes on next view
- **Manual refresh**: User can tap refresh button

### Cost Optimization

- **Model**: Claude 3.5 Haiku (most cost-effective)
- **Max tokens**: 150 tokens (short, concise responses)
- **Caching**: 1 hour cache prevents redundant calls
- **Prompts**: Minimal system prompts (20-50 tokens each)

**Estimated cost per insight**: ~$0.0001 - $0.0002 USD

### Network Efficiency

- Async/await for non-blocking UI
- Loading states show user feedback
- Error handling with graceful degradation
- Request timeout: 30 seconds (default URLSession)

## Error Handling

The `InsightCard` handles errors gracefully:

- **API errors**: Shows error message with retry button
- **Network failures**: Displays user-friendly error
- **Missing API key**: Fails with clear error message
- **Invalid context**: Returns minimal response

## Testing

### Test with Sample Data

```swift
// Preview with test data
#Preview {
    InsightCard(
        type: .awardAnalysis,
        context: InsightContext(
            awardData: [
                AwardOffer(program: "United MileagePlus", miles: 70000, cabin: "Business"),
                AwardOffer(program: "Air Canada Aeroplan", miles: 60000, cabin: "Business")
            ],
            origin: "JFK",
            destination: "LHR"
        ),
        airlineColors: AirlineColorService.shared.getBrandColors(for: "UA")
    )
    .padding()
}
```

### Verify Accuracy

- Compare generated insights against known facts
- Test with various routes and aircraft types
- Validate award comparisons match provided data
- Ensure no speculation or recommendations appear

### Cache Testing

```swift
// Clear cache for testing
InsightsCacheService.shared.clearCache()

// Force refresh
await viewModel.refresh(type: .destination, context: context)
```

## Prompt Engineering Best Practices

### Rules Embedded in Prompts

Each insight type has strict rules in its system prompt:
- "Only compare data provided"
- "No recommendations"
- "No speculation"
- "2-3 sentences maximum"

### Keeping Prompts Lean

- System prompts: 20-50 tokens
- User prompts: 30-100 tokens
- Total context: ~100-200 tokens per request
- Response: ~50-150 tokens

### Context Specificity

Provide only relevant data:
```swift
// Good - minimal context
InsightContext(
    origin: "SFO",
    destination: "LAX",
    distance: 337
)

// Avoid - unnecessary context
InsightContext(
    origin: "SFO",
    destination: "LAX",
    distance: 337,
    departureTime: Date(), // Not needed for route context
    aircraftType: "737"    // Not needed for route context
)
```

## Future Enhancements

Potential additions:
- [ ] Multi-language support
- [ ] Seasonal insights (weather patterns, busy seasons)
- [ ] Historical price trends (if data available)
- [ ] Connection insights for multi-leg routes
- [ ] Alliance information and benefits
- [ ] Lounge access information

## Troubleshooting

### No Insights Appearing

1. Check API key is set in build configuration
2. Verify Info.plist includes ANTHROPIC_KEY entry
3. Check console for error messages
4. Ensure context has required fields populated

### Slow Response Times

1. Check network connectivity
2. Verify cache is working (second views should be instant)
3. Consider reducing max_tokens if responses are too long

### Inaccurate Information

1. Review the prompt in `ClaudePromptBuilder.swift`
2. Ensure context data is accurate
3. File an issue with example for review
4. Consider tightening system prompt rules

## Support

For issues or questions:
- Check console logs for detailed error messages
- Review prompt builder for insight type configuration
- Test with minimal context to isolate issues
- Verify API key has sufficient credits

## License

This integration follows the same license as FlightApp.
