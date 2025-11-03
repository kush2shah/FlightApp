# Data Models

## Overview

This document defines all data models for Amadeus API integration, including request/response models, comparison models, and UI presentation models.

## File Organization

```
FlightApp/Models/
├── Amadeus/
│   ├── FlightOffer.swift           # Core flight offer model
│   ├── PriceMetrics.swift          # Price analytics model
│   ├── DetailedPricing.swift       # Enhanced pricing details
│   └── AmadeusCommon.swift         # Shared types (Price, Location, etc.)
└── Comparison/
    ├── MatchedOffer.swift          # Award + Cash comparison
    ├── ValueAnalysis.swift         # Value calculations
    └── BookingRecommendation.swift # Smart recommendations
```

---

## Core Amadeus Models

### FlightOffer.swift

```swift
import Foundation

/// Complete flight offer from Amadeus API
struct FlightOffer: Codable, Identifiable {
    let id: String
    let type: String
    let source: String
    let instantTicketingRequired: Bool?
    let nonHomogeneous: Bool?
    let oneWay: Bool?
    let lastTicketingDate: String?
    let numberOfBookableSeats: Int?
    let itineraries: [Itinerary]
    let price: Price
    let pricingOptions: PricingOptions?
    let validatingAirlineCodes: [String]
    let travelerPricings: [TravelerPricing]?

    /// Get primary itinerary (outbound)
    var outbound: Itinerary? {
        itineraries.first
    }

    /// Get return itinerary if exists
    var inbound: Itinerary? {
        itineraries.count > 1 ? itineraries[1] : nil
    }

    /// Total price as Double
    var totalPrice: Double {
        Double(price.total) ?? 0
    }

    /// Base price as Double
    var basePrice: Double {
        Double(price.base ?? "0") ?? 0
    }

    /// Total fees as Double
    var totalFees: Double {
        totalPrice - basePrice
    }

    /// Formatted total price (e.g., "$450.00")
    var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = price.currency
        return formatter.string(from: NSNumber(value: totalPrice)) ?? price.total
    }

    /// First airline code (for branding)
    var primaryAirline: String? {
        validatingAirlineCodes.first ?? outbound?.segments.first?.carrierCode
    }

    /// Total journey duration
    var totalDuration: String? {
        outbound?.duration
    }

    /// Number of stops
    var numberOfStops: Int {
        max(0, (outbound?.segments.count ?? 1) - 1)
    }
}

// MARK: - Itinerary

struct Itinerary: Codable {
    let duration: String  // ISO 8601 duration (e.g., "PT2H30M")
    let segments: [FlightSegment]

    /// Human-readable duration (e.g., "2h 30m")
    var formattedDuration: String {
        duration.replacingOccurrences(of: "PT", with: "")
            .replacingOccurrences(of: "H", with: "h ")
            .replacingOccurrences(of: "M", with: "m")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Total number of stops
    var stops: Int {
        max(0, segments.count - 1)
    }

    /// Departure airport
    var origin: String {
        segments.first?.departure.iataCode ?? ""
    }

    /// Arrival airport
    var destination: String {
        segments.last?.arrival.iataCode ?? ""
    }
}

// MARK: - Flight Segment

struct FlightSegment: Codable, Identifiable {
    let id: String?
    let departure: FlightEndpoint
    let arrival: FlightEndpoint
    let carrierCode: String
    let number: String
    let aircraft: Aircraft
    let operating: OperatingFlight?
    let duration: String
    let stops: Int?
    let blacklistedInEU: Bool?

    var flightNumber: String {
        "\(carrierCode)\(number)"
    }

    var formattedDuration: String {
        duration.replacingOccurrences(of: "PT", with: "")
            .replacingOccurrences(of: "H", with: "h ")
            .replacingOccurrences(of: "M", with: "m")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Flight Endpoint (Departure/Arrival)

struct FlightEndpoint: Codable {
    let iataCode: String
    let terminal: String?
    let at: String  // ISO 8601 datetime

    var date: Date? {
        ISO8601DateFormatter().date(from: at)
    }

    var formattedTime: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var formattedDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Aircraft

struct Aircraft: Codable {
    let code: String  // IATA aircraft code (e.g., "77W" for 777-300ER)

    var displayName: String {
        // Could map to friendly names
        code
    }
}

// MARK: - Operating Flight

struct OperatingFlight: Codable {
    let carrierCode: String
    let number: String?

    var flightNumber: String {
        if let number = number {
            return "\(carrierCode)\(number)"
        }
        return carrierCode
    }
}

// MARK: - Price

struct Price: Codable {
    let currency: String
    let total: String
    let base: String?
    let fees: [Fee]?
    let grandTotal: String?
    let billingCurrency: String?

    var totalAsDouble: Double {
        Double(total) ?? 0
    }

    var baseAsDouble: Double {
        Double(base ?? "0") ?? 0
    }

    var totalFees: Double {
        fees?.reduce(0) { $0 + ($1.amountAsDouble) } ?? 0
    }
}

// MARK: - Fee

struct Fee: Codable {
    let amount: String
    let type: String

    var amountAsDouble: Double {
        Double(amount) ?? 0
    }
}

// MARK: - Pricing Options

struct PricingOptions: Codable {
    let fareType: [String]?
    let includedCheckedBagsOnly: Bool?
}

// MARK: - Traveler Pricing

struct TravelerPricing: Codable {
    let travelerId: String
    let fareOption: String
    let travelerType: String
    let price: Price
    let fareDetailsBySegment: [FareDetailsBySegment]
}

// MARK: - Fare Details

struct FareDetailsBySegment: Codable {
    let segmentId: String
    let cabin: String?  // ECONOMY, PREMIUM_ECONOMY, BUSINESS, FIRST
    let fareBasis: String?
    let brandedFare: String?
    let `class`: String?
    let includedCheckedBags: IncludedCheckedBags?

    enum CabinClass: String, Codable {
        case economy = "ECONOMY"
        case premiumEconomy = "PREMIUM_ECONOMY"
        case business = "BUSINESS"
        case first = "FIRST"
    }

    var cabinClass: CabinClass? {
        guard let cabin = cabin else { return nil }
        return CabinClass(rawValue: cabin)
    }
}

// MARK: - Included Bags

struct IncludedCheckedBags: Codable {
    let quantity: Int?
    let weight: Int?
    let weightUnit: String?
}
```

---

### PriceMetrics.swift

```swift
import Foundation

/// Historical price analytics for a route
struct PriceMetrics: Codable, Identifiable {
    let type: String
    let origin: String
    let destination: String
    let departureDate: String
    let currency: String
    let priceMetrics: [PriceMetric]

    var id: String {
        "\(origin)-\(destination)-\(departureDate)"
    }

    /// Get metric for specific quartile
    func metric(for quartile: QuartileRanking) -> PriceMetric? {
        priceMetrics.first { $0.quartileRanking == quartile.rawValue }
    }

    /// Get overall price range
    var priceRange: (min: Double, max: Double)? {
        guard let min = priceMetrics.min(by: { $0.amount < $1.amount }),
              let max = priceMetrics.max(by: { $0.amount < $1.amount }) else {
            return nil
        }
        return (min.amount, max.amount)
    }

    /// Get median price
    var medianPrice: Double? {
        metric(for: .medium)?.amount
    }
}

// MARK: - Price Metric

struct PriceMetric: Codable {
    let amount: String
    let quartileRanking: String

    var amount: Double {
        Double(amount) ?? 0
    }

    var ranking: QuartileRanking? {
        QuartileRanking(rawValue: quartileRanking)
    }
}

// MARK: - Quartile Ranking

enum QuartileRanking: String, Codable, CaseIterable {
    case minimum = "MINIMUM"
    case first = "FIRST"
    case medium = "MEDIUM"
    case third = "THIRD"
    case maximum = "MAXIMUM"

    var displayName: String {
        switch self {
        case .minimum: return "Lowest"
        case .first: return "Low"
        case .medium: return "Average"
        case .third: return "High"
        case .maximum: return "Highest"
        }
    }

    var icon: String {
        switch self {
        case .minimum: return "arrow.down.circle.fill"
        case .first: return "arrow.down.circle"
        case .medium: return "equal.circle"
        case .third: return "arrow.up.circle"
        case .maximum: return "arrow.up.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .minimum, .first: return "green"
        case .medium: return "orange"
        case .third, .maximum: return "red"
        }
    }
}
```

---

## Comparison Models

### MatchedOffer.swift

```swift
import Foundation

/// Combines award availability with cash pricing for comparison
struct MatchedOffer: Identifiable {
    let id = UUID()
    let date: String
    let origin: String
    let destination: String

    let award: AwardAvailability?
    let cashOffer: FlightOffer?
    let priceMetrics: PriceMetrics?

    /// Whether both award and cash data are available
    var hasComparison: Bool {
        award != nil && cashOffer != nil
    }

    /// Whether only cash is available
    var cashOnly: Bool {
        award == nil && cashOffer != nil
    }

    /// Whether only award is available
    var awardOnly: Bool {
        award != nil && cashOffer == nil
    }

    /// Best available award cabin
    var bestAwardCabin: (cabin: String, cost: String, seats: Int)? {
        award?.bestAvailableCabin()
    }

    /// Cash price for comparable cabin
    var cashPriceForCabin: Double? {
        guard let cashOffer = cashOffer else { return nil }
        // Default to total price if can't match cabin
        return cashOffer.totalPrice
    }

    /// Value analysis if comparison is possible
    var valueAnalysis: ValueAnalysis? {
        guard hasComparison,
              let awardCabin = bestAwardCabin,
              let cashPrice = cashPriceForCabin else {
            return nil
        }

        guard let miles = Double(awardCabin.cost.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }

        return ValueAnalysis(
            cashPrice: cashPrice,
            awardMiles: miles,
            cabin: awardCabin.cabin,
            remainingSeats: awardCabin.seats,
            programName: award?.source ?? "",
            priceQuartile: determineQuartile()
        )
    }

    /// Determine price quartile ranking
    private func determineQuartile() -> QuartileRanking? {
        guard let cashPrice = cashPriceForCabin,
              let metrics = priceMetrics else {
            return nil
        }

        // Compare against historical quartiles
        if cashPrice <= (metrics.metric(for: .minimum)?.amount ?? 0) {
            return .minimum
        } else if cashPrice <= (metrics.metric(for: .first)?.amount ?? 0) {
            return .first
        } else if cashPrice <= (metrics.metric(for: .medium)?.amount ?? 0) {
            return .medium
        } else if cashPrice <= (metrics.metric(for: .third)?.amount ?? 0) {
            return .third
        } else {
            return .maximum
        }
    }
}
```

---

### ValueAnalysis.swift

```swift
import Foundation

/// Analyzes the value of using miles vs cash
struct ValueAnalysis {
    let cashPrice: Double
    let awardMiles: Double
    let cabin: String
    let remainingSeats: Int
    let programName: String
    let priceQuartile: QuartileRanking?

    /// Cents per mile/point value
    var centsPerPoint: Double {
        guard awardMiles > 0 else { return 0 }
        return (cashPrice / awardMiles) * 100
    }

    /// Dollar savings if using miles
    var savingsIfUsingMiles: Double {
        cashPrice  // Assumes you "save" the full cash price
    }

    /// Formatted cents per point (e.g., "2.8¢")
    var formattedCPP: String {
        String(format: "%.1f¢", centsPerPoint)
    }

    /// Value rating (poor, fair, good, excellent)
    var valueRating: ValueRating {
        switch centsPerPoint {
        case 0..<0.8:
            return .poor
        case 0.8..<1.2:
            return .fair
        case 1.2..<2.0:
            return .good
        case 2.0...:
            return .excellent
        default:
            return .poor
        }
    }

    /// Booking recommendation
    var recommendation: BookingRecommendation {
        // Excellent value: Always recommend miles
        if valueRating == .excellent {
            return .useAward(
                reason: "Excellent value at \(formattedCPP)/point",
                savingsDollars: savingsIfUsingMiles
            )
        }

        // Good value + low cash price: Consider cash
        if valueRating == .good && (priceQuartile == .minimum || priceQuartile == .first) {
            return .considerCash(
                reason: "Good award value but cash price is historically low",
                cashPrice: cashPrice
            )
        }

        // Good value: Recommend miles
        if valueRating == .good {
            return .useAward(
                reason: "Good value at \(formattedCPP)/point",
                savingsDollars: savingsIfUsingMiles
            )
        }

        // Fair value + few seats: Act fast
        if valueRating == .fair && remainingSeats <= 2 {
            return .useAward(
                reason: "Only \(remainingSeats) seat(s) left",
                savingsDollars: savingsIfUsingMiles
            )
        }

        // Fair value + high cash price: Use miles
        if valueRating == .fair && (priceQuartile == .third || priceQuartile == .maximum) {
            return .useAward(
                reason: "Cash price is high, better to use miles",
                savingsDollars: savingsIfUsingMiles
            )
        }

        // Fair value otherwise: Neutral
        if valueRating == .fair {
            return .neutral(
                reason: "Fair value at \(formattedCPP)/point - either option works"
            )
        }

        // Poor value: Pay cash
        return .payCash(
            reason: "Poor value at \(formattedCPP)/point - better to pay cash",
            cashPrice: cashPrice
        )
    }
}

// MARK: - Value Rating

enum ValueRating: String, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"

    var color: String {
        switch self {
        case .poor: return "red"
        case .fair: return "orange"
        case .good: return "blue"
        case .excellent: return "green"
        }
    }

    var icon: String {
        switch self {
        case .poor: return "hand.thumbsdown.fill"
        case .fair: return "hand.thumbsup"
        case .good: return "hand.thumbsup.fill"
        case .excellent: return "sparkles"
        }
    }
}
```

---

### BookingRecommendation.swift

```swift
import Foundation

/// Smart recommendation for how to book
enum BookingRecommendation {
    case useAward(reason: String, savingsDollars: Double)
    case payCash(reason: String, cashPrice: Double)
    case considerCash(reason: String, cashPrice: Double)
    case neutral(reason: String)

    var title: String {
        switch self {
        case .useAward:
            return "Book with Miles"
        case .payCash:
            return "Pay with Cash"
        case .considerCash:
            return "Consider Cash"
        case .neutral:
            return "Either Option"
        }
    }

    var reason: String {
        switch self {
        case .useAward(let reason, _),
             .payCash(let reason, _),
             .considerCash(let reason, _),
             .neutral(let reason):
            return reason
        }
    }

    var icon: String {
        switch self {
        case .useAward:
            return "star.fill"
        case .payCash:
            return "dollarsign.circle.fill"
        case .considerCash:
            return "dollarsign.circle"
        case .neutral:
            return "equal.circle"
        }
    }

    var color: String {
        switch self {
        case .useAward:
            return "green"
        case .payCash:
            return "blue"
        case .considerCash:
            return "orange"
        case .neutral:
            return "gray"
        }
    }

    var detailText: String? {
        switch self {
        case .useAward(_, let savings):
            return "Save $\(String(format: "%.0f", savings))"
        case .payCash(_, let price),
             .considerCash(_, let price):
            return "$\(String(format: "%.0f", price))"
        case .neutral:
            return nil
        }
    }
}
```

---

## Helper Extensions

### Date Formatting

```swift
extension String {
    /// Parse YYYY-MM-DD date string
    var asDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)
    }

    /// Format as display date (e.g., "Jan 15, 2025")
    var asDisplayDate: String {
        guard let date = asDate else { return self }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    /// Format as short date (e.g., "Jan 15")
    var asShortDate: String {
        guard let date = asDate else { return self }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
```

### Cabin Class Mapping

```swift
extension AwardAvailability {
    /// Map award cabin code to display name
    func cabinDisplayName(for code: String) -> String {
        switch code {
        case "F": return "First"
        case "J": return "Business"
        case "W": return "Premium Economy"
        case "Y": return "Economy"
        default: return code
        }
    }
}

extension FlightOffer {
    /// Get primary cabin class
    var primaryCabin: String? {
        travelerPricings?.first?.fareDetailsBySegment.first?.cabin
    }

    var primaryCabinDisplay: String {
        guard let cabin = primaryCabin else { return "Economy" }
        switch cabin {
        case "FIRST": return "First"
        case "BUSINESS": return "Business"
        case "PREMIUM_ECONOMY": return "Premium Economy"
        case "ECONOMY": return "Economy"
        default: return cabin
        }
    }
}
```

---

## Model Usage Examples

### Creating a Matched Offer

```swift
// From RouteViewModel
func createMatchedOffers() -> [MatchedOffer] {
    var matches: [String: MatchedOffer] = [:]

    // Add all awards
    for award in awards {
        matches[award.date] = MatchedOffer(
            date: award.date,
            origin: originIata ?? "",
            destination: destinationIata ?? "",
            award: award,
            cashOffer: nil,
            priceMetrics: priceMetrics
        )
    }

    // Match cash offers by date
    for offer in cashOffers {
        let date = offer.outbound?.segments.first?.departure.at.prefix(10) ?? ""
        let dateString = String(date)

        if var existing = matches[dateString] {
            existing.cashOffer = offer
            matches[dateString] = existing
        } else {
            matches[dateString] = MatchedOffer(
                date: dateString,
                origin: originIata ?? "",
                destination: destinationIata ?? "",
                award: nil,
                cashOffer: offer,
                priceMetrics: priceMetrics
            )
        }
    }

    return Array(matches.values).sorted { $0.date < $1.date }
}
```

### Displaying Value Analysis

```swift
// In RouteView
if let analysis = matchedOffer.valueAnalysis {
    VStack(alignment: .leading, spacing: 4) {
        HStack {
            Image(systemName: analysis.recommendation.icon)
            Text(analysis.recommendation.title)
                .font(.headline)
        }
        .foregroundColor(Color(analysis.recommendation.color))

        Text(analysis.recommendation.reason)
            .font(.subheadline)
            .foregroundColor(.secondary)

        if let detail = analysis.recommendation.detailText {
            Text(detail)
                .font(.caption)
                .bold()
        }
    }
}
```

## Model Validation

All models include:
- ✅ Codable conformance for JSON parsing
- ✅ Identifiable for SwiftUI lists
- ✅ Computed properties for UI display
- ✅ Optional chaining for safe unwrapping
- ✅ Type-safe enums for categories
- ✅ Formatted output methods
- ✅ Value comparison logic
