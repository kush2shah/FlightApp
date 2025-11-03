# UI Integration Design

## Overview

This document outlines the UI components, layout, and user experience for displaying cash prices and value comparisons in FlightApp.

---

## Design Principles

### 1. **Simple First**
Start with basic cash price display, then add sophisticated analysis

### 2. **Non-Blocking**
Cash prices are nice-to-have; don't prevent award data from showing

### 3. **Liquid Glass Aesthetic**
Match existing design language with glassmorphic effects

### 4. **Haptic Feedback**
Maintain aggressive haptic patterns for interactions

### 5. **Information Density**
Show actionable data without overwhelming the user

---

## Component Hierarchy

```
RouteView
├── Route Map (existing)
├── Current Flights (existing)
├── Award Availability (existing)
├── Cash Prices (NEW - Phase 1)
│   └── CashPriceCard (simple display)
└── Value Comparison (NEW - Phase 2+)
    └── ValueComparisonCard (advanced analysis)
```

---

## Phase 1: Simple Cash Price Display

### CashPriceCard Component

**Location**: `FlightApp/Views/Route/CashPriceCard.swift`

**Purpose**: Display cash flight offers in a clean, simple format

**Design**:
```
┌─────────────────────────────────────────────┐
│  AA 123 • 10:30 AM → 2:45 PM               │
│  ✈️ American Airlines                       │
│  ────────────────────────────────────────   │
│  Economy         $450                       │
│  Business        $2,850                     │
│  Duration: 5h 15m • Nonstop                 │
└─────────────────────────────────────────────┘
```

**Implementation**:

```swift
import SwiftUI

struct CashPriceCard: View {
    let offer: FlightOffer
    @State private var isExpanded = false

    var body: some View {
        GlassEffectContainer {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Flight number and times
                HStack {
                    if let segment = offer.outbound?.segments.first {
                        Text("\(segment.carrierCode) \(segment.number)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(segment.departure.formattedTime)
                            .font(.system(.subheadline, design: .rounded))

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(segment.arrival.formattedTime)
                            .font(.system(.subheadline, design: .rounded))
                    }

                    Spacer()
                }

                // Airline name
                if let airline = offer.primaryAirline {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(airlineName(for: airline))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Price by cabin (simplified)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(offer.primaryCabinDisplay)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(offer.formattedTotalPrice)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                }

                // Flight details
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(offer.outbound?.formattedDuration ?? "")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: stopIcon)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(stopText)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var stopIcon: String {
        offer.numberOfStops == 0 ? "arrow.right" : "arrow.triangle.branch"
    }

    private var stopText: String {
        offer.numberOfStops == 0 ? "Nonstop" : "\(offer.numberOfStops) stop\(offer.numberOfStops == 1 ? "" : "s")"
    }

    private func airlineName(for code: String) -> String {
        // TODO: Map to airline names via AirlineService
        code
    }
}
```

### Integration into RouteView

**Location**: `FlightApp/Views/Route/RouteView.swift`

**Add after Award Availability section** (around line 220):

```swift
// MARK: - Cash Prices Section

if FeatureFlags.shared.canUseAmadeus && !viewModel.cashOffers.isEmpty {
    Section {
        VStack(spacing: 16) {
            ForEach(viewModel.cashOffers.prefix(10)) { offer in
                CashPriceCard(offer: offer)
                    .onTapGesture {
                        HapticManager.shared.impact(style: .medium)
                        // Future: Show details
                    }
            }

            if viewModel.cashOffers.count > 10 {
                Text("Showing first 10 cash prices")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    } header: {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.green)

            Text("Cash Prices")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)

            Spacer()

            if viewModel.isLoadingCashPrices {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 8)
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.clear)
}

// Show loading state
if FeatureFlags.shared.canUseAmadeus && viewModel.isLoadingCashPrices {
    Section {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading cash prices...")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
    } header: {
        HStack {
            Image(systemName: "dollarsign.circle")
                .foregroundColor(.green)
            Text("Cash Prices")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
        }
        .padding(.vertical, 8)
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.clear)
}

// Show error state
if FeatureFlags.shared.canUseAmadeus,
   !viewModel.isLoadingCashPrices,
   viewModel.cashOffers.isEmpty,
   viewModel.cashPriceError != nil {
    Section {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Cash prices unavailable")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
    } header: {
        HStack {
            Image(systemName: "dollarsign.circle")
                .foregroundColor(.green)
            Text("Cash Prices")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
        }
        .padding(.vertical, 8)
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.clear)
}
```

---

## Phase 2: Value Comparison Display

### ValueComparisonCard Component

**Location**: `FlightApp/Views/Route/ValueComparisonCard.swift`

**Purpose**: Show award vs cash comparison with smart recommendations

**Design**:
```
┌──────────────────────────────────────────────┐
│  ⭐ Book with Miles                          │
│  Excellent value at 4.1¢/point              │
│  ────────────────────────────────────────    │
│  💳 Cash: $2,850                             │
│  ✨ Miles: 70,000 pts                        │
│  💰 Save $2,850 (4 seats left)               │
│  ────────────────────────────────────────    │
│  📊 Price is VERY LOW vs. historical         │
└──────────────────────────────────────────────┘
```

**Implementation**:

```swift
import SwiftUI

struct ValueComparisonCard: View {
    let matchedOffer: MatchedOffer

    var body: some View {
        guard let analysis = matchedOffer.valueAnalysis else {
            return AnyView(EmptyView())
        }

        return AnyView(
            GlassEffectContainer {
                VStack(alignment: .leading, spacing: 16) {
                    // Recommendation header
                    HStack(spacing: 8) {
                        Image(systemName: analysis.recommendation.icon)
                            .font(.title3)
                            .foregroundColor(Color(analysis.recommendation.color))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(analysis.recommendation.title)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)

                            Text(analysis.recommendation.reason)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    Divider()

                    // Price comparison
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "creditcard")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Cash")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Text("$\(String(format: "%.0f", analysis.cashPrice))")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "star")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Miles")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Text("\(String(format: "%.0f", analysis.awardMiles)) pts")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                        }
                    }

                    // Value metrics
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Value: \(analysis.formattedCPP) per point")
                                .font(.system(.caption, design: .rounded))

                            Spacer()

                            // Value rating badge
                            Text(analysis.valueRating.rawValue)
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(analysis.valueRating.color))
                                )
                        }

                        if analysis.remainingSeats <= 4 {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)

                                Text("Only \(analysis.remainingSeats) seat\(analysis.remainingSeats == 1 ? "" : "s") left")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    // Historical price context
                    if let quartile = analysis.priceQuartile {
                        Divider()

                        HStack(spacing: 6) {
                            Image(systemName: quartile.icon)
                                .font(.caption)
                                .foregroundColor(Color(quartile.color))

                            Text("Price is \(quartile.displayName.uppercased()) vs. historical")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        )
    }
}
```

### Integration into RouteView

Add **new section** for value comparisons (Phase 2+):

```swift
// MARK: - Value Comparison Section

if FeatureFlags.shared.canUseAmadeus,
   !viewModel.matchedOffers.isEmpty {
    Section {
        VStack(spacing: 16) {
            ForEach(viewModel.matchedOffers.filter { $0.hasComparison }.prefix(10)) { match in
                ValueComparisonCard(matchedOffer: match)
                    .onTapGesture {
                        HapticManager.shared.impact(style: .medium)
                        // Future: Show detailed comparison
                    }
            }
        }
    } header: {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(.purple)

            Text("Value Analysis")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.vertical, 8)
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.clear)
}
```

---

## Loading States

### Skeleton Loaders

```swift
struct CashPriceSkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        GlassEffectContainer {
            VStack(alignment: .leading, spacing: 12) {
                // Flight number skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 120, height: 16)

                // Price skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 80, height: 24)

                // Details skeleton
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 60, height: 12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 60, height: 12)
                }
            }
            .padding()
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// Usage in RouteView
if viewModel.isLoadingCashPrices {
    ForEach(0..<3, id: \.self) { _ in
        CashPriceSkeletonCard()
    }
}
```

---

## Empty States

### No Cash Prices Available

```swift
struct NoCashPricesView: View {
    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 12) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("No cash prices found")
                    .font(.system(.headline, design: .rounded))

                Text("Try different dates or check back later")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
    }
}
```

---

## Interaction Patterns

### Tap to Expand

Future enhancement for Phase 2+:

```swift
struct CashPriceCard: View {
    let offer: FlightOffer
    @State private var isExpanded = false

    var body: some View {
        GlassEffectContainer {
            VStack(alignment: .leading, spacing: 12) {
                // Basic info always visible
                basicInfo

                if isExpanded {
                    // Expanded details
                    Divider()
                    expandedDetails
                }
            }
            .padding()
        }
        .onTapGesture {
            HapticManager.shared.impact(style: .medium)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
    }

    private var basicInfo: some View {
        // ... basic card content
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            // All segments
            ForEach(offer.outbound?.segments ?? []) { segment in
                SegmentDetailRow(segment: segment)
            }

            // Baggage info
            if let bags = offer.travelerPricings?.first?.fareDetailsBySegment.first?.includedCheckedBags {
                BaggageInfoRow(bags: bags)
            }

            // Pricing breakdown
            PricingBreakdown(price: offer.price)
        }
    }
}
```

### Pull to Refresh

Add to RouteView:

```swift
.refreshable {
    HapticManager.shared.impact(style: .light)
    await viewModel.refreshAll()
}
```

---

## Accessibility

### VoiceOver Support

```swift
struct CashPriceCard: View {
    // ...

    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityHint("Double tap to view details")
    }

    private var accessibilityDescription: String {
        var desc = "\(offer.primaryAirline ?? "Flight") for \(offer.formattedTotalPrice)"

        if let duration = offer.totalDuration {
            desc += ", \(duration)"
        }

        if offer.numberOfStops == 0 {
            desc += ", nonstop"
        } else {
            desc += ", \(offer.numberOfStops) stop\(offer.numberOfStops == 1 ? "" : "s")"
        }

        return desc
    }
}
```

### Dynamic Type Support

```swift
.font(.system(.headline, design: .rounded))
.dynamicTypeSize(.large ... .xxxLarge) // Limit extreme sizes
```

---

## Responsive Design

### Compact vs Regular Size Classes

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var body: some View {
    if horizontalSizeClass == .compact {
        compactLayout
    } else {
        regularLayout
    }
}

private var compactLayout: some View {
    // Stacked vertical layout
    VStack { /* ... */ }
}

private var regularLayout: some View {
    // Side-by-side layout for iPad
    HStack { /* ... */ }
}
```

---

## Dark Mode Support

All components use semantic colors:
- `.primary` for main text
- `.secondary` for supporting text
- `Color("BrandColor")` for brand elements
- Automatically adapt to dark mode

---

## Animation & Transitions

### Smooth Appearances

```swift
ForEach(viewModel.cashOffers) { offer in
    CashPriceCard(offer: offer)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
}
.animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.cashOffers)
```

### Loading Shimmer

```swift
.overlay(
    shimmerOverlay
        .opacity(isLoading ? 1 : 0)
)

private var shimmerOverlay: some View {
    LinearGradient(...)
        .offset(x: shimmerOffset)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
}
```

---

## Error States

### Inline Error Messages

```swift
if let error = viewModel.cashPriceError {
    GlassEffectContainer {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Unable to load prices")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)

                Text(error.localizedDescription)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Retry") {
                HapticManager.shared.impact(style: .light)
                Task {
                    await viewModel.loadCashPrices()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

---

## Future Enhancements

### Phase 3+
1. **Price Chart**: 30-day price calendar view
2. **Filter & Sort**: By price, duration, stops, airline
3. **Multi-Passenger**: Family pricing display
4. **Booking Links**: Deep link to airline websites
5. **Price Alerts**: Set target price notifications
6. **Share**: Export comparison to share sheet

### Long-term
1. **AR Price Overlay**: View prices in AR flight tracker
2. **Widgets**: Home screen price widgets
3. **Watch App**: Glanceable price checks
4. **Siri Integration**: "Hey Siri, check prices to Tokyo"
