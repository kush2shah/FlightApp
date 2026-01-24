//
//  RouteView.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct RouteView: View {
    let origin: String
    let destination: String

    @StateObject private var viewModel = RouteViewModel()
    @State private var selectedFlight: IdentifiableString?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Liquid glass background layer
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        if viewModel.isLoading {
                            loadingView
                        } else if let error = viewModel.error {
                            errorView(error)
                        } else {
                            routeContentView
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("\(origin) → \(destination)")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedFlight) { identifiableFlightNumber in
                FlightView(flightNumber: identifiableFlightNumber.value, faFlightId: identifiableFlightNumber.faFlightId, skipFlightSelection: true)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
            }
        }
        .task {
            await viewModel.loadRouteData(origin: origin, destination: destination)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            // Loading Icon - matches error view pattern
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "airplane")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .symbolEffect(.pulse, options: .repeating)
                )

            VStack(spacing: 8) {
                Text("Loading Route")
                    .font(.sfRounded(size: 24, weight: .bold))
                Text("Fetching route information...")
                    .font(.sfRounded(size: 15))
                    .foregroundColor(.secondary)
            }

            // Progress indicator to show active loading
            ProgressView()
                .tint(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            // Error Icon
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                )

            // Error Message
            VStack(spacing: 8) {
                Text("Error Loading Route")
                    .font(.sfRounded(size: 24, weight: .bold))
                Text(error)
                    .font(.sfRounded(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private var routeContentView: some View {
        VStack(spacing: 0) {
            // Route map (hero section) with stats overlay
            // Show map even without IFR route data - great circle is calculated independently
            if viewModel.originAirport != nil && viewModel.destinationAirport != nil {
                RouteMapSection(
                    origin: viewModel.originAirport,
                    destination: viewModel.destinationAirport,
                    route: viewModel.primaryRoute
                )
                .frame(height: 400)
            }

            // Show content if we have flights, awards, or cash offers (or if still loading)
            // Don't block on cash price loading - show what we have
            if viewModel.currentFlights.isEmpty && viewModel.awards.isEmpty && viewModel.cashOffers.isEmpty && !viewModel.isLoading && !viewModel.isLoadingCashPrices {
                emptyRouteState
            } else {
                VStack(spacing: 32) {
                    // Current flights section (primary focus)
                    if !viewModel.currentFlights.isEmpty {
                        currentFlightsSection
                    }

                    // Award availability section (only show if we have awards, no "no awards" message)
                    if !viewModel.awards.isEmpty {
                        awardAvailabilitySection

                        // Award insights
                        InsightCard(
                            type: .awardAnalysis,
                            context: buildAwardContext(),
                            airlineColors: getAirlineColors()
                        )
                        .padding(.horizontal, 24)
                    }

                    // Route context insights (always show when we have route data)
                    if viewModel.originAirport != nil && viewModel.destinationAirport != nil {
                        InsightCard(
                            type: .routeContext,
                            context: buildRouteContext(),
                            airlineColors: getAirlineColors()
                        )
                        .padding(.horizontal, 24)
                    }

                    // Cash prices section (NEW)
                    cashPricesSection
                }
                .padding(.vertical, 32)
            }
        }
    }

    private var emptyRouteState: some View {
        VStack(spacing: 24) {
            // Empty State Icon
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                )

            // Empty State Message
            VStack(spacing: 8) {
                Text("No Flights Found")
                    .font(.sfRounded(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                Text("There are no scheduled flights on this route today. Try searching for a different date or route.")
                    .font(.sfRounded(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var currentFlightsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Explore Flights")
                    .font(.sfRounded(size: 28, weight: .bold))
                Spacer()
                if viewModel.currentFlights.count > 10 {
                    Text("\(viewModel.currentFlights.count) total")
                        .font(.sfRounded(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(sortedFlights.prefix(10)) { flight in
                    Button(action: {
                        selectedFlight = IdentifiableString(value: flight.ident, faFlightId: flight.faFlightId)
                    }) {
                        FlightRowCard(flight: flight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)

            if viewModel.currentFlights.count > 10 {
                Text("Showing first 10 flights")
                    .font(.sfRounded(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // Prioritize in-progress flights, then sort by departure time
    private var sortedFlights: [AeroFlight] {
        viewModel.currentFlights.sorted { flight1, flight2 in
            // Prioritize in-progress flights
            if flight1.isInProgress && !flight2.isInProgress {
                return true
            } else if !flight1.isInProgress && flight2.isInProgress {
                return false
            }

            // Then sort by scheduled departure time
            if let time1 = flight1.scheduledOut, let time2 = flight2.scheduledOut {
                return time1 < time2
            }

            return false
        }
    }

    private var awardAvailabilitySection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Simple header
            HStack {
                Text("Awards")
                    .font(.sfRounded(size: 28, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 24)

            // Nested dropdowns: Cabin → Program → Dates
            VStack(spacing: 0) {
                let cabinsWithAwards = [CabinClass.economy, .premiumEconomy, .business, .first]
                    .filter { viewModel.hasAwardsForCabin($0) }
                
                ForEach(Array(cabinsWithAwards.enumerated()), id: \.element) { index, cabin in
                    CabinAwardRow(
                        cabin: cabin,
                        awards: viewModel.awards,
                        origin: origin,
                        destination: destination
                    )
                    
                    // Add divider between cabin sections (but not after the last one)
                    if index < cabinsWithAwards.count - 1 {
                        Divider()
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Cash Prices Section

    @ViewBuilder
    private var cashPricesSection: some View {
        if FeatureFlags.shared.canUseAmadeus {
            VStack(alignment: .leading, spacing: 24) {
                // Simple header
                HStack {
                    Text("Cash Fares")
                        .font(.sfRounded(size: 28, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 24)

                // Content based on load state
                if viewModel.isLoadingCashPrices {
                    // Loading with progress bar
                    VStack(spacing: 16) {
                        // Animated airplane icon
                        Image(systemName: "airplane")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                            .symbolEffect(.pulse, options: .repeating)

                        Text("Loading fares in cash...")
                            .font(.sfRounded(size: 15))
                            .foregroundColor(.secondary)

                        // Progress bar showing search progress
                        ProgressView(value: viewModel.cashPriceLoadingProgress, total: Double(viewModel.cashPriceLoadingTotal))
                            .tint(.blue)
                            .frame(maxWidth: 200)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.clear)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    )
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

                } else if !viewModel.cashOffers.isEmpty {
                    // BLUF - Show best price only
                    if let bestOffer = viewModel.cashOffers.first {
                        BestCashPriceRow(offer: bestOffer)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                } else if viewModel.cashPriceError != nil {
                    // Error state
                    Text("Prices unavailable")
                        .font(.sfRounded(size: 15))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoadingCashPrices)
        }
    }

    // MARK: - Insight Context Builders

    private func getAirlineColors() -> AirlineBrandColors? {
        // Try to get airline from first current flight
        let airlineCode = viewModel.currentFlights.first?.operatorIata
        guard let code = airlineCode else { return nil }
        return AirlineColorService.shared.getBrandColors(for: code)
    }

    private func buildAwardContext() -> InsightContext {
        // Build list of unique award offers across all cabins
        var awardOffers: [AwardOffer] = []

        for award in viewModel.awards {
            let source = award.source

            // Check each cabin class
            if award.jAvailable == true, let milesStr = award.jMileageCost, let miles = Int(milesStr) {
                awardOffers.append(AwardOffer(program: source, miles: miles, cabin: "Business"))
            }
            if award.fAvailable == true, let milesStr = award.fMileageCost, let miles = Int(milesStr) {
                awardOffers.append(AwardOffer(program: source, miles: miles, cabin: "First"))
            }
            if award.yAvailable == true, let milesStr = award.yMileageCost, let miles = Int(milesStr) {
                awardOffers.append(AwardOffer(program: source, miles: miles, cabin: "Economy"))
            }
            if award.wAvailable == true, let milesStr = award.wMileageCost, let miles = Int(milesStr) {
                awardOffers.append(AwardOffer(program: source, miles: miles, cabin: "Premium Economy"))
            }
        }

        return InsightContext(
            awardData: awardOffers.isEmpty ? nil : awardOffers,
            origin: origin,
            destination: destination
        )
    }

    private func buildRouteContext() -> InsightContext {
        // Calculate route distance if we have coordinates
        var distance: Double?
        if let orig = viewModel.originAirport,
           let dest = viewModel.destinationAirport,
           let origLat = orig.latitude,
           let origLon = orig.longitude,
           let destLat = dest.latitude,
           let destLon = dest.longitude {
            let location1 = CLLocation(latitude: origLat, longitude: origLon)
            let location2 = CLLocation(latitude: destLat, longitude: destLon)
            let distanceMeters = location1.distance(from: location2)
            distance = distanceMeters / 1609.34 // Convert meters to miles
        }

        // Duration - we can't easily parse the string times, so skip for now
        // Claude can still provide insights without duration
        let duration: TimeInterval? = nil

        return InsightContext(
            origin: origin,
            destination: destination,
            distance: distance,
            duration: duration,
            destinationAirport: destination,
            destinationCity: viewModel.destinationAirport?.city
        )
    }
}

// MARK: - Route Map Section

struct RouteMapSection: View {
    let origin: AeroAirport?
    let destination: AeroAirport?
    let route: IFRRouteInfo?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let origin = origin,
               let destination = destination,
               let originCoord = AirportCoordinateService.shared.getCoordinate(for: origin.displayCode),
               let destCoord = AirportCoordinateService.shared.getCoordinate(for: destination.displayCode) {
                SimpleRouteMapView(
                    originLat: originCoord.coordinate.latitude,
                    originLon: originCoord.coordinate.longitude,
                    destLat: destCoord.coordinate.latitude,
                    destLon: destCoord.coordinate.longitude
                )

                // Stats overlay with glass effect
                HStack(spacing: 24) {
                    // Only show distance if we have route data
                    if let route = route {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Distance")
                                .font(.sfRounded(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(route.routeDistance)
                                .font(.sfRounded(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        Divider()
                            .frame(height: 30)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Route")
                            .font(.sfRounded(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            Text(origin.displayCode)
                                .font(.sfRounded(size: 18, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            Text(destination.displayCode)
                                .font(.sfRounded(size: 18, weight: .bold))
                        }
                        .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            } else {
                Color(.systemGray6)
                VStack {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Map unavailable")
                        .font(.sfRounded(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// Simple map view showing route line
struct SimpleRouteMapView: UIViewRepresentable {
    let originLat: Double
    let originLon: Double
    let destLat: Double
    let destLon: Double

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Clear existing overlays
        mapView.removeOverlays(mapView.overlays)

        // Validate coordinates
        guard isValidCoordinate(latitude: originLat, longitude: originLon),
              isValidCoordinate(latitude: destLat, longitude: destLon) else {
            print("⚠️ Invalid coordinates detected, skipping map update")
            return
        }

        let origin = CLLocationCoordinate2D(latitude: originLat, longitude: originLon)
        let dest = CLLocationCoordinate2D(latitude: destLat, longitude: destLon)

        // Create great circle arc (curved path) between airports
        let arcCoordinates = createGreatCircleArc(from: origin, to: dest, points: 100)
        
        // Only add overlay if we got valid coordinates
        if !arcCoordinates.isEmpty {
            let polyline = MKPolyline(coordinates: arcCoordinates, count: arcCoordinates.count)
            mapView.addOverlay(polyline)
        }

        // Calculate safe region that handles transoceanic flights
        if let region = calculateSafeRegion(from: origin, to: dest) {
            mapView.setRegion(region, animated: false)
        } else {
            // Fallback: show a reasonable default view centered on origin
            let fallbackRegion = MKCoordinateRegion(
                center: origin,
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
            mapView.setRegion(fallbackRegion, animated: false)
        }
    }

    // Create great circle arc between two points

    // Validate that coordinates are within valid ranges
    private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180 &&
               !latitude.isNaN && !longitude.isNaN &&
               !latitude.isInfinite && !longitude.isInfinite
    }
    
    // Calculate a safe region that handles edge cases like transoceanic flights
    private func calculateSafeRegion(from origin: CLLocationCoordinate2D, to dest: CLLocationCoordinate2D) -> MKCoordinateRegion? {
        // Calculate the center point
        let centerLat = (origin.latitude + dest.latitude) / 2
        var centerLon = (origin.longitude + dest.longitude) / 2
        
        // Handle date line crossing for longitude
        let lonDiff = abs(origin.longitude - dest.longitude)
        if lonDiff > 180 {
            // Flight crosses the date line
            let adjustedOriginLon = origin.longitude < 0 ? origin.longitude + 360 : origin.longitude
            let adjustedDestLon = dest.longitude < 0 ? dest.longitude + 360 : dest.longitude
            centerLon = (adjustedOriginLon + adjustedDestLon) / 2
            if centerLon > 180 {
                centerLon -= 360
            }
        }
        
        // Calculate span with safety limits
        let latDelta = abs(origin.latitude - dest.latitude)
        let lonDelta = min(lonDiff, 360 - lonDiff) // Handle wrap-around
        
        // Add padding but cap at reasonable maximums
        // For transoceanic flights, we want to show the route but not too much ocean
        let paddingMultiplier: Double = 1.4
        let safeLatDelta = min(latDelta * paddingMultiplier + 10, 160) // Max ~160° (leave poles visible)
        let safeLonDelta = min(lonDelta * paddingMultiplier + 20, 340) // Max ~340° (almost full wrap)
        
        // Ensure minimum span for very close airports
        let finalLatDelta = max(safeLatDelta, 5)
        let finalLonDelta = max(safeLonDelta, 5)
        
        // Validate the final region
        guard isValidCoordinate(latitude: centerLat, longitude: centerLon),
              finalLatDelta > 0 && finalLatDelta <= 180,
              finalLonDelta > 0 && finalLonDelta <= 360 else {
            print("⚠️ Calculated region is invalid")
            return nil
        }
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLonDelta)
        )
    }

    // Create great circle arc between two points
    private func createGreatCircleArc(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, points: Int) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []

        // Validate input coordinates
        guard isValidCoordinate(latitude: start.latitude, longitude: start.longitude),
              isValidCoordinate(latitude: end.latitude, longitude: end.longitude) else {
            print("⚠️ Invalid coordinates for great circle arc")
            return []
        }

        // Convert to radians
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180

        // Calculate great circle distance
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let d = 2 * atan2(sqrt(a), sqrt(1 - a))

        // Check for degenerate cases
        if d.isNaN || d.isInfinite || d < 0.0001 {
            // Points are too close or calculation failed, return straight line
            print("⚠️ Degenerate case in great circle calculation, using straight line")
            return [start, end]
        }

        let sinD = sin(d)
        
        // Another safety check for division by zero
        if abs(sinD) < 0.0001 {
            print("⚠️ sin(d) too close to zero, using straight line")
            return [start, end]
        }

        // Generate points along the arc
        for i in 0...points {
            let fraction = Double(i) / Double(points)

            let a = sin((1 - fraction) * d) / sinD
            let b = sin(fraction * d) / sinD

            let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
            let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
            let z = a * sin(lat1) + b * sin(lat2)

            let lat = atan2(z, sqrt(x * x + y * y))
            let lon = atan2(y, x)

            let latDeg = lat * 180 / .pi
            let lonDeg = lon * 180 / .pi

            // Validate each calculated point
            if isValidCoordinate(latitude: latDeg, longitude: lonDeg) {
                coordinates.append(CLLocationCoordinate2D(
                    latitude: latDeg,
                    longitude: lonDeg
                ))
            } else {
                print("⚠️ Invalid coordinate generated at point \(i), skipping")
            }
        }

        // If we didn't get enough valid points, fall back to simple line
        if coordinates.count < 2 {
            print("⚠️ Not enough valid points in arc, using straight line")
            return [start, end]
        }

        return coordinates
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Flight Row Card

struct FlightRowCard: View {
    let flight: AeroFlight

    private var airlineCode: String? {
        flight.operatorIata ?? flight.operatorIcao
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Airline logo
                if let code = airlineCode {
                    AirlineLogoView(iataCode: code, size: 48)
                } else {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                }

                // Flight info
                VStack(alignment: .leading, spacing: 6) {
                    Text(flight.ident)
                        .font(.sfRounded(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    if let aircraftName = AircraftTypeService.shared.getAircraftName(from: flight.aircraftType) {
                        Text(aircraftName)
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                    }

                    // Status badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusText)
                            .font(.sfRounded(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }

                Spacer()

                // Time info
                VStack(alignment: .trailing, spacing: 4) {
                    if let scheduledOut = flight.scheduledOut {
                        Text(formatTime(scheduledOut))
                            .font(.sfRounded(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Text("Departure")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // Date info at bottom
            if let scheduledOut = flight.scheduledOut {
                Divider()
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatDate(scheduledOut))
                        .font(.sfRounded(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }

    private var statusColor: Color {
        if flight.isInProgress {
            return .green
        } else if flight.status.lowercased().contains("cancelled") {
            return .red
        } else if flight.status.lowercased().contains("delayed") {
            return .orange
        }
        return .blue
    }

    private var statusText: String {
        if flight.isInProgress {
            return "In Flight"
        } else if flight.status.lowercased().contains("cancelled") {
            return "Cancelled"
        } else if flight.status.lowercased().contains("delayed") {
            return "Delayed"
        }
        return "Scheduled"
    }

    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return timeFormatter.string(from: date)
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
}

// MARK: - Award Filter Bar

struct AwardFilterBar: View {
    @Binding var filters: AwardFilters
    let availablePrograms: [String]

    @State private var showDatePicker = false
    @State private var showProgramsMenu = false

    var body: some View {
        VStack(spacing: 12) {
            // Cabin class chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CabinClass.allCases, id: \.self) { cabin in
                        CabinChip(
                            cabin: cabin,
                            isSelected: filters.selectedCabins.contains(cabin),
                            onTap: {
                                HapticManager.shared.impact(.soft)
                                if filters.selectedCabins.contains(cabin) {
                                    filters.selectedCabins.remove(cabin)
                                } else {
                                    filters.selectedCabins.insert(cabin)
                                }
                            }
                        )
                    }

                    Divider()
                        .frame(height: 24)

                    // Date range button
                    Button(action: {
                        HapticManager.shared.impact(.soft)
                        showDatePicker.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12, weight: .medium))
                            Text("\(filters.dateRange.daysCount) days")
                                .font(.sfRounded(size: 13, weight: .medium))
                        }
                        .foregroundColor(filters.dateRange == .next30Days ? .secondary : .blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }

                    // Mileage programs filter
                    if !availablePrograms.isEmpty {
                        Menu {
                            ForEach(availablePrograms, id: \.self) { program in
                                Button(action: {
                                    HapticManager.shared.impact(.soft)
                                    if filters.selectedPrograms.contains(program) {
                                        filters.selectedPrograms.remove(program)
                                    } else {
                                        filters.selectedPrograms.insert(program)
                                    }
                                }) {
                                    HStack {
                                        Text(program)
                                        if filters.selectedPrograms.contains(program) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            if !filters.selectedPrograms.isEmpty {
                                Divider()
                                Button("Clear Program Filter", action: {
                                    HapticManager.shared.impact(.light)
                                    filters.selectedPrograms.removeAll()
                                })
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 12, weight: .medium))
                                if filters.selectedPrograms.isEmpty {
                                    Text("All Programs")
                                        .font(.sfRounded(size: 13, weight: .medium))
                                } else {
                                    Text("\(filters.selectedPrograms.count) selected")
                                        .font(.sfRounded(size: 13, weight: .medium))
                                }
                            }
                            .foregroundColor(filters.selectedPrograms.isEmpty ? .secondary : .blue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            // Date range picker (shown when expanded)
            if showDatePicker {
                VStack(spacing: 12) {
                    Text("Search Date Range")
                        .font(.sfRounded(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        DateRangeButton(title: "Next 7 Days", range: .next7Days, currentRange: $filters.dateRange)
                        DateRangeButton(title: "Next 30 Days", range: .next30Days, currentRange: $filters.dateRange)
                        DateRangeButton(title: "Next 60 Days", range: .next60Days, currentRange: $filters.dateRange)
                        DateRangeButton(title: "Next 90 Days", range: .next90Days, currentRange: $filters.dateRange)
                    }
                }
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct CabinChip: View {
    let cabin: CabinClass
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: cabin.icon)
                    .font(.system(size: 12, weight: .medium))
                Text(cabin.displayName)
                    .font(.sfRounded(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        Color.blue
                    } else {
                        Color.clear
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }
                }
            )
            .cornerRadius(16)
        }
    }
}

struct DateRangeButton: View {
    let title: String
    let range: DateRange
    @Binding var currentRange: DateRange

    var isSelected: Bool {
        currentRange == range
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.soft)
            currentRange = range
        }) {
            HStack {
                Text(title)
                    .font(.sfRounded(size: 14, weight: .medium))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundColor(isSelected ? .blue : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(10)
        }
    }
}

// MARK: - Award Row Card

struct AwardRowCard: View {
    let award: AwardAvailability
    let isRecommended: Bool
    let origin: String
    let destination: String

    @State private var showAllCabins = false

    var body: some View {
        let bookingURL = award.generateBookingURL(origin: origin, destination: destination)

        Button(action: {
            HapticManager.shared.impact(.light)
            if let bookingURL = bookingURL {
                UIApplication.shared.open(bookingURL)
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    // Date icon and info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            Text(formatDate(award.date))
                                .font(.sfRounded(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            if isRecommended {
                                Text("Best Value")
                                    .font(.sfRounded(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(6)
                            }
                        }
                        Text(formatProgram(award.source))
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Book button - only show if we have a valid booking URL
                    if bookingURL != nil {
                        BookButton {
                            // Action is already handled by the outer Button
                        }
                    }
                }

                // Best available cabin (always shown)
                if let cabin = award.bestAvailableCabin() {
                    HStack {
                        HStack(spacing: 4) {
                            Text(cabin.cost)
                                .font(.sfRounded(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                            Text("pts")
                                .font(.sfRounded(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text(cabin.cabin)
                                .font(.sfRounded(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            Text("• \(cabin.seats) left")
                                .font(.sfRounded(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Show all available cabins if expanded
                if showAllCabins {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All Available Cabins")
                            .font(.sfRounded(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        ForEach(award.allAvailableCabins(), id: \.cabin) { cabin in
                            HStack {
                                Image(systemName: cabin.cabin.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                    .frame(width: 20)

                                Text(cabin.cabin.displayName)
                                    .font(.sfRounded(size: 13, weight: .medium))

                                Spacer()

                                Text("\(cabin.cost) pts")
                                    .font(.sfRounded(size: 13, weight: .semibold))
                                    .foregroundColor(.blue)

                                Text("• \(cabin.seats) left")
                                    .font(.sfRounded(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Toggle button for all cabins (only show if multiple cabins available)
                if award.allAvailableCabins().count > 1 {
                    Button(action: {
                        HapticManager.shared.impact(.soft)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAllCabins.toggle()
                        }
                    }) {
                        HStack {
                            Text(showAllCabins ? "Show Less" : "Show All Cabins (\(award.allAvailableCabins().count))")
                                .font(.sfRounded(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                            Image(systemName: showAllCabins ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatProgram(_ source: String) -> String {
        MileageProgramService.shared.getProgramName(from: source)
    }
}

// MARK: - BLUF Components

struct BestAwardRow: View {
    let cabin: CabinClass
    let award: AwardAvailability
    let origin: String
    let destination: String
    let allAwards: [AwardAvailability]

    @State private var showingCabinFlights = false

    // Get all awards for this cabin
    private var cabinAwards: [AwardAvailability] {
        allAwards.filter { $0.isCabinAvailable(cabin) }
            .sorted { award1, award2 in
                guard let cost1String = award1.getMileageCost(for: cabin),
                      let cost2String = award2.getMileageCost(for: cabin) else {
                    return false
                }
                let cost1 = Int(cost1String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                let cost2 = Int(cost2String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                return cost1 < cost2
            }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            showingCabinFlights = true
        }) {
            HStack(spacing: 16) {
                // Cabin icon
                Image(systemName: cabin.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 40)

                // Cabin name
                VStack(alignment: .leading, spacing: 2) {
                    Text(cabin.displayName)
                        .font(.sfRounded(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    if let seats = award.getRemainingSeats(for: cabin) {
                        Text("\(seats) left")
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Points cost
                if let cost = award.getMileageCost(for: cabin) {
                    HStack(spacing: 4) {
                        Text(cost)
                            .font(.sfRounded(size: 20, weight: .bold))
                            .foregroundColor(.blue)
                        Text("pts")
                            .font(.sfRounded(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingCabinFlights) {
            CabinAwardsSheet(cabin: cabin, awards: cabinAwards, origin: origin, destination: destination)
        }
    }
}

// Sheet showing all awards for a specific cabin class
struct CabinAwardsSheet: View {
    let cabin: CabinClass
    let awards: [AwardAvailability]
    let origin: String
    let destination: String
    @Environment(\.dismiss) private var dismiss
    
    // Group awards by mileage program
    private var groupedAwards: [(program: String, awards: [AwardAvailability])] {
        let programGroups = Dictionary(grouping: awards) { award in
            MileageProgramService.shared.getProgramName(from: award.source)
        }
        return programGroups
            .sorted { $0.key < $1.key }
            .map { (program: $0.key, awards: $0.value.sorted { award1, award2 in
                // Sort by date within each program
                award1.date < award2.date
            })}
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(groupedAwards, id: \.program) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            // Program header
                            HStack {
                                Text(group.program)
                                    .font(.sfRounded(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(group.awards.count)")
                                    .font(.sfRounded(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 4)
                            
                            // Awards for this program
                            VStack(spacing: 12) {
                                ForEach(group.awards) { award in
                                    AwardRowCard(award: award, isRecommended: false, origin: origin, destination: destination)
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(cabin.displayName) Awards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Program Award Group (for Awards section)

/// Groups awards by mileage program and shows best fare with expandable list
/// Cabin-level row that expands to show programs
struct CabinAwardRow: View {
    let cabin: CabinClass
    let awards: [AwardAvailability]
    let origin: String
    let destination: String
    
    @State private var isExpanded = false
    
    // Group awards by program
    // Group awards by program
    private var programGroups: [(program: String, awards: [AwardAvailability])] {
        let groups = Dictionary(grouping: awards.filter { $0.isCabinAvailable(cabin) }) { award in
            award.programName
        }
        return groups
            .map { (program: $0.key, awards: $0.value.sorted { $0.date < $1.date }) }
            .sorted { group1, group2 in
                // Sort program groups by their best (lowest) award price
                let bestCost1 = group1.awards
                    .compactMap { award -> Int? in
                        guard let costString = award.getMileageCost(for: cabin) else { return nil }
                        return Int(costString.replacingOccurrences(of: ",", with: ""))
                    }
                    .min() ?? Int.max
                
                let bestCost2 = group2.awards
                    .compactMap { award -> Int? in
                        guard let costString = award.getMileageCost(for: cabin) else { return nil }
                        return Int(costString.replacingOccurrences(of: ",", with: ""))
                    }
                    .min() ?? Int.max
                
                return bestCost1 < bestCost2
            }
    }
    
    // Best (lowest cost) award across all programs for this cabin
    private var bestAward: AwardAvailability? {
        awards
            .filter { $0.isCabinAvailable(cabin) }
            .min { award1, award2 in
                guard let cost1String = award1.getMileageCost(for: cabin),
                      let cost2String = award2.getMileageCost(for: cabin) else {
                    return false
                }
                let cost1 = Int(cost1String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                let cost2 = Int(cost2String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                return cost1 < cost2
            }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main cabin row (always visible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.impact(.light)
            }) {
                HStack(spacing: 16) {
                    // Cabin icon
                    Image(systemName: cabin.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .frame(width: 40)
                    
                    // Cabin name and program count
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cabin.displayName)
                            .font(.sfRounded(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text("\(programGroups.count) program\(programGroups.count == 1 ? "" : "s")")
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Best points cost
                    if let best = bestAward, let cost = best.getMileageCost(for: cabin) {
                        HStack(spacing: 4) {
                            Text("from")
                                .font(.sfRounded(size: 11))
                                .foregroundColor(.secondary)
                            Text(cost)
                                .font(.sfRounded(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("pts")
                                .font(.sfRounded(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .frame(width: 14)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded programs list
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 76)
                    
                    ForEach(Array(programGroups.enumerated()), id: \.element.program) { index, group in
                        ProgramAwardGroup(
                            programName: group.program,
                            awards: group.awards,
                            cabin: cabin,
                            origin: origin,
                            destination: destination
                        )
                        
                        if index < programGroups.count - 1 {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// Program-level row within a cabin that expands to show dates
struct ProgramAwardGroup: View {
    let programName: String
    let awards: [AwardAvailability]
    let cabin: CabinClass
    let origin: String
    let destination: String

    @State private var isExpanded = false

    // Get airline logo image name from the source code
    private var airlineImageName: String? {
        guard let firstAward = awards.first else { return nil }
        return MileageProgramService.shared.getImageName(from: firstAward.source)
    }

    // Get the best (lowest cost) award for this program and cabin
    private var bestAward: AwardAvailability? {
        awards
            .filter { $0.isCabinAvailable(cabin) }
            .min { award1, award2 in
                guard let cost1String = award1.getMileageCost(for: cabin),
                      let cost2String = award2.getMileageCost(for: cabin) else {
                    return false
                }
                let cost1 = Int(cost1String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                let cost2 = Int(cost2String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                return cost1 < cost2
            }
    }
    
    // Get all other awards (for pagination)
    // Get all other awards (for pagination)
    private var additionalAwards: [AwardAvailability] {
        guard let best = bestAward else { return [] }
        return awards
            .filter { $0.isCabinAvailable(cabin) && $0.id != best.id }
            .sorted { award1, award2 in
                // Sort by mileage cost (ascending - cheapest first)
                guard let cost1String = award1.getMileageCost(for: cabin),
                      let cost2String = award2.getMileageCost(for: cabin) else {
                    return false
                }
                let cost1 = Int(cost1String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                let cost2 = Int(cost2String.replacingOccurrences(of: ",", with: "")) ?? Int.max
                
                // Primary sort: by cost
                if cost1 != cost2 {
                    return cost1 < cost2
                }
                
                // Secondary sort: by date (earlier dates first)
                return award1.date < award2.date
            }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Best fare row (always visible)
            if let best = bestAward {
                Button(action: {
                    if !additionalAwards.isEmpty {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                        HapticManager.shared.impact(.light)
                    }
                }) {
                    HStack(spacing: 12) {
                        // Indent spacer
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 40)
                        
                        // Program logo using AirlineLogoView
                        AirlineLogoView(iataCode: airlineImageName, size: 36)
                            .frame(width: 36, height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(programName)
                                    .font(.sfRounded(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                if !additionalAwards.isEmpty {
                                    Text("+\(additionalAwards.count)")
                                        .font(.sfRounded(size: 11, weight: .medium))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            
                            // Date info
                            if let parsedDate = best.parsedDate {
                                Text(formatDate(parsedDate))
                                    .font(.sfRounded(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer(minLength: 8)
                        
                        // Points cost
                        if let cost = best.getMileageCost(for: cabin) {
                            HStack(spacing: 4) {
                                Text(cost)
                                    .font(.sfRounded(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text("pts")
                                    .font(.sfRounded(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        
                        // Expand indicator (only if there are more dates)
                        if !additionalAwards.isEmpty {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .frame(width: 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.02))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Expanded additional fares
            if isExpanded && !additionalAwards.isEmpty {
                VStack(spacing: 0) {
                    ForEach(additionalAwards.prefix(5)) { award in
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                // Double indent
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 88)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if let parsedDate = award.parsedDate {
                                        Text(formatDate(parsedDate))
                                            .font(.sfRounded(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                    }
                                    
                                    if let seats = award.getRemainingSeats(for: cabin) {
                                        Text("\(seats) seat\(seats == 1 ? "" : "s") left")
                                            .font(.sfRounded(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer(minLength: 8)
                                
                                if let cost = award.getMileageCost(for: cabin) {
                                    HStack(spacing: 4) {
                                        Text(cost)
                                            .font(.sfRounded(size: 14, weight: .bold))
                                            .foregroundColor(.blue)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        Text("pts")
                                            .font(.sfRounded(size: 10, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.01))
                            
                            if award.id != additionalAwards.prefix(5).last?.id {
                                Divider()
                                    .padding(.leading, 88)
                            }
                        }
                    }
                    
                    // Show more indicator if there are more than 5 additional awards
                    if additionalAwards.count > 5 {
                        HStack {
                            Text("+\(additionalAwards.count - 5) more dates available")
                                .font(.sfRounded(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 88)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.03))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct BestCashPriceRow: View {
    let offer: FlightOffer

    private var airlineCode: String? {
        offer.outbound?.segments.first?.carrierCode
    }

    private var displayName: String {
        guard let firstSegment = offer.outbound?.segments.first else {
            return "Flight"
        }

        let airlineName = firstSegment.airlineName

        // If airline name lookup failed and returned just the code,
        // show the flight number instead for better UX
        if airlineName == firstSegment.carrierCode {
            return "Flight \(firstSegment.flightNumber)"
        }

        return airlineName
    }

    var body: some View {
        HStack(spacing: 16) {
            // Airline logo
            if let code = airlineCode {
                AirlineLogoView(iataCode: code, size: 56)
                    .frame(width: 56, height: 56)
            } else {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
                    .frame(width: 56, height: 56)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Airline name or flight number
                Text(displayName)
                    .font(.sfRounded(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Date
                if let departure = offer.outbound?.segments.first?.departure {
                    Text(departure.formattedDate)
                        .font(.sfRounded(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Flight details
                HStack(spacing: 6) {
                    if offer.numberOfStops == 0 {
                        Text("Nonstop")
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.green)
                    } else {
                        Text("\(offer.numberOfStops) \(offer.numberOfStops == 1 ? "stop" : "stops")")
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                    }
                    if let duration = offer.outbound?.duration {
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(formatDuration(duration))
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Price - emphasized but not overwhelming
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(Int(offer.totalPrice))")
                    .font(.sfRounded(size: 32, weight: .bold))
                    .foregroundColor(.green)
                    .lineLimit(1)
                Text("USD")
                    .font(.sfRounded(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        )
    }

    private func formatDuration(_ duration: String) -> String {
        // Parse "PT7H30M" to "7h 30m"
        var result = duration.replacingOccurrences(of: "PT", with: "")
        result = result.replacingOccurrences(of: "H", with: "h ")
        result = result.replacingOccurrences(of: "M", with: "m")
        return result
    }
}

#Preview {
    RouteView(origin: "JFK", destination: "LHR")
}
