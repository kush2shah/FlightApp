//
//  RouteView.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import SwiftUI
import MapKit

struct RouteView: View {
    let origin: String
    let destination: String

    @StateObject private var viewModel = RouteViewModel()
    @State private var selectedFlight: IdentifiableString?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        routeContentView
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(origin) → \(destination)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedFlight) { identifiableFlightNumber in
                FlightView(flightNumber: identifiableFlightNumber.value, faFlightId: identifiableFlightNumber.faFlightId, skipFlightSelection: true)
                    .presentationDragIndicator(.visible)
            }
        }
        .task {
            await viewModel.loadRouteData(origin: origin, destination: destination)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading route information...")
                .font(.sfRounded(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Error Loading Route")
                .font(.sfRounded(size: 20, weight: .semibold))
            Text(error)
                .font(.sfRounded(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
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

            // Show content if we have flights, otherwise show empty state
            if viewModel.currentFlights.isEmpty && viewModel.awards.isEmpty && !viewModel.isLoading {
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
                    }
                }
                .padding(.vertical, 32)
            }
        }
    }

    private var emptyRouteState: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 56))
                .foregroundColor(.secondary)

            Text("No Flights Found")
                .font(.sfRounded(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text("There are no scheduled flights on this route today. Try searching for a different date or route.")
                .font(.sfRounded(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Award Availability")
                    .font(.sfRounded(size: 28, weight: .bold))
                Spacer()
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal)

            VStack(spacing: 14) {
                ForEach(viewModel.awards.prefix(20)) { award in
                    AwardRowCard(award: award)
                }
            }
            .padding(.horizontal)

            if viewModel.awards.count > 20 {
                Text("Showing first 20 results")
                    .font(.sfRounded(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
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

// MARK: - Award Row Card

struct AwardRowCard: View {
    let award: AwardAvailability

    var body: some View {
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
                }
                Text(formatProgram(award.source))
                    .font(.sfRounded(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let cabin = award.bestAvailableCabin() {
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(cabin.cost)
                            .font(.sfRounded(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                        Text("pts")
                            .font(.sfRounded(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
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
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatProgram(_ source: String) -> String {
        source.capitalized.replacingOccurrences(of: "_", with: " ")
    }
}

#Preview {
    RouteView(origin: "JFK", destination: "LHR")
}
