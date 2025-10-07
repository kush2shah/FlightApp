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
    @State private var selectedFlightNumber: String?
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
            .sheet(item: Binding(
                get: { selectedFlightNumber.map { IdentifiableString(value: $0) } },
                set: { selectedFlightNumber = $0?.value }
            )) { identifiableFlightNumber in
                FlightView(flightNumber: identifiableFlightNumber.value, skipFlightSelection: true)
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
            // Route map (hero section)
            if let primaryRoute = viewModel.primaryRoute {
                RouteMapSection(
                    origin: viewModel.originAirport,
                    destination: viewModel.destinationAirport,
                    route: primaryRoute
                )
                .frame(height: 300)
            }

            VStack(spacing: 24) {
                // Route overview stats
                if let primaryRoute = viewModel.primaryRoute {
                    routeOverviewSection(primaryRoute)
                }

                // Operator & aircraft stats
                if viewModel.hasAggregateStats {
                    aggregateStatsSection
                }

                // Current flights section
                if !viewModel.currentFlights.isEmpty {
                    currentFlightsSection
                }

                // Award availability section
                if !viewModel.awards.isEmpty {
                    awardAvailabilitySection
                } else if viewModel.shouldShowAwards {
                    noAwardsView
                }
            }
            .padding(.vertical, 24)
        }
    }

    private func routeOverviewSection(_ route: IFRRouteInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route Details")
                .font(.sfRounded(size: 20, weight: .bold))
                .padding(.horizontal)

            VStack(spacing: 16) {
                // Distance and altitude
                HStack(spacing: 20) {
                    StatBox(
                        icon: "arrow.left.and.right",
                        label: "Distance",
                        value: route.routeDistance
                    )
                    StatBox(
                        icon: "arrow.up",
                        label: "Altitude",
                        value: "FL\(route.filedAltitudeMin/100)-\(route.filedAltitudeMax/100)"
                    )
                }

                // IFR Route
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "map")
                            .foregroundColor(.blue)
                        Text("Filed IFR Route")
                            .font(.sfRounded(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    Text(route.route)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }

    private var aggregateStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Common Operators & Aircraft")
                .font(.sfRounded(size: 20, weight: .bold))
                .padding(.horizontal)

            VStack(spacing: 12) {
                if !viewModel.commonAircraft.isEmpty {
                    InfoCard(
                        icon: "airplane",
                        title: "Common Aircraft",
                        items: viewModel.commonAircraft
                    )
                }

                if !viewModel.totalFlightCount.isEmpty {
                    HStack {
                        Image(systemName: "chart.bar")
                            .foregroundColor(.blue)
                        Text("\(viewModel.totalFlightCount) flights filed on this route")
                            .font(.sfRounded(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
        }
    }

    private var currentFlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flights on This Route")
                .font(.sfRounded(size: 22, weight: .bold))
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(viewModel.currentFlights.prefix(10)) { flight in
                    Button(action: {
                        selectedFlightNumber = flight.ident
                    }) {
                        FlightRowCard(flight: flight)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }

    private var awardAvailabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Award Availability")
                    .font(.sfRounded(size: 22, weight: .bold))
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(viewModel.awards.prefix(20)) { award in
                    AwardRowCard(award: award)
                }
            }
            .padding(.horizontal)

            if viewModel.awards.count > 20 {
                Text("Showing top 20 results")
                    .font(.sfRounded(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
    }

    private var noAwardsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.slash")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No award availability found")
                .font(.sfRounded(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Helper Components

struct StatBox: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                Text(label)
                    .font(.sfRounded(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.sfRounded(size: 18, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.sfRounded(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.sfRounded(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Route Map Section

struct RouteMapSection: View {
    let origin: AeroAirport?
    let destination: AeroAirport?
    let route: IFRRouteInfo

    var body: some View {
        ZStack {
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
        let origin = CLLocationCoordinate2D(latitude: originLat, longitude: originLon)
        let dest = CLLocationCoordinate2D(latitude: destLat, longitude: destLon)

        // Add route line
        let coordinates = [origin, dest]
        let polyline = MKPolyline(coordinates: coordinates, count: 2)
        mapView.addOverlay(polyline)

        // Fit to show both airports
        let midLat = (originLat + destLat) / 2
        let midLon = (originLon + destLon) / 2
        let latDelta = abs(originLat - destLat) * 1.5
        let lonDelta = abs(originLon - destLon) * 1.5

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
            span: MKCoordinateSpan(latitudeDelta: max(latDelta, 5), longitudeDelta: max(lonDelta, 5))
        )
        mapView.setRegion(region, animated: false)
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

    var body: some View {
        HStack(spacing: 16) {
            // Flight number
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.ident)
                    .font(.sfRounded(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                if let operatorIata = flight.operatorIata {
                    Text(operatorIata)
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Time info
            VStack(alignment: .trailing, spacing: 4) {
                if let scheduledOut = flight.scheduledOut {
                    Text(formatTime(scheduledOut))
                        .font(.sfRounded(size: 14, weight: .medium))
                }
                if flight.isInProgress {
                    Text("In Flight")
                        .font(.sfRounded(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    Text("Scheduled")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, h:mm a"
        return timeFormatter.string(from: date)
    }
}

// MARK: - Award Row Card

struct AwardRowCard: View {
    let award: AwardAvailability

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(award.date))
                    .font(.sfRounded(size: 14, weight: .semibold))
                Text(formatProgram(award.source))
                    .font(.sfRounded(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let cabin = award.bestAvailableCabin() {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(cabin.cost)
                            .font(.sfRounded(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                        Text("pts")
                            .font(.sfRounded(size: 12))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Text(cabin.cabin)
                            .font(.sfRounded(size: 12, weight: .medium))
                        Text("(\(cabin.seats) left)")
                            .font(.sfRounded(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
