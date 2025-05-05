//
//  FlightRouteVisualization.swift
//  FlightApp
//
//  Created by Kush Shah on 5/4/25.
//

import SwiftUI
import MapKit

struct FlightPosition: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let timestamp: Date
    let updateType: String?
    let heading: Int?
    let groundspeed: Int?
    
    // Create a CLLocationCoordinate2D for map display
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Service to fetch flight position data from AeroAPI
class FlightPositionService {
    static let shared = FlightPositionService()
    private let baseURL = "https://aeroapi.flightaware.com/aeroapi"
    
    private var apiKey: String {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AERO_API_KEY") as? String {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        print("❌ No API key found in Info.plist")
        return ""
    }
    
    // Fetch flight positions from AeroAPI for a specific flight
    func fetchFlightPositions(for flight: AeroFlight) async throws -> [FlightPosition] {
        guard !flight.faFlightId.isEmpty else {
            throw AeroAPIError.invalidURL
        }
        
        guard let url = URL(string: "\(baseURL)/flights/\(flight.faFlightId)/positions") else {
            throw AeroAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")
        
        print("🔍 Fetching flight positions: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AeroAPIError.invalidResponse
            }
            
            // Handle error responses
            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 429:
                    throw AeroAPIError.rateLimitExceeded
                case 404:
                    throw AeroAPIError.noFlightsFound
                default:
                    throw AeroAPIError.serverError(httpResponse.statusCode)
                }
            }
            
            // For debugging purposes
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📊 Positions Response: \(jsonString.prefix(500))...")
            }
            
            // Decode the response
            struct PositionsResponse: Decodable {
                let positions: [Position]
                
                struct Position: Decodable {
                    let latitude: Double
                    let longitude: Double
                    let altitude: Int
                    let timestamp: String
                    let update_type: String?
                    let groundspeed: Int
                    let heading: Int?
                }
            }
            
            let decoder = JSONDecoder()
            let positionsResponse = try decoder.decode(PositionsResponse.self, from: data)
            
            // Convert API positions to our model
            let formatter = ISO8601DateFormatter()
            
            return positionsResponse.positions.compactMap { position in
                guard let date = formatter.date(from: position.timestamp) else {
                    return nil
                }
                
                return FlightPosition(
                    latitude: position.latitude,
                    longitude: position.longitude,
                    altitude: Double(position.altitude) * 100, // Convert to feet (API returns hundreds of feet)
                    timestamp: date,
                    updateType: position.update_type,
                    heading: position.heading,
                    groundspeed: position.groundspeed
                )
            }
        } catch {
            print("❌ Error fetching positions: \(error)")
            throw error
        }
    }
    
    // Get default airport coordinates if they're needed for placeholder data
    func getCoordinatesForAirport(_ code: String) -> CLLocationCoordinate2D? {
        // This is a simplified lookup for demonstration
        // In a real app, you would use a more comprehensive airport database
        let airports: [String: (lat: Double, lng: Double)] = [
            "JFK": (40.6413, -73.7781),
            "LAX": (33.9416, -118.4085),
            "LHR": (51.4700, -0.4543),
            "SFO": (37.6213, -122.3790),
            "ORD": (41.9742, -87.9073),
            "DFW": (32.8998, -97.0403),
            "ATL": (33.6407, -84.4277),
            "AMS": (52.3105, 4.7683),
            "CDG": (49.0097, 2.5479),
            "DXB": (25.2532, 55.3657),
            "SIN": (1.3644, 103.9915),
            "HND": (35.5494, 139.7798),
            "SYD": (-33.9399, 151.1753)
        ]
        
        // Try to find airport in our simplified database
        if let coordinates = airports[code] {
            return CLLocationCoordinate2D(latitude: coordinates.lat, longitude: coordinates.lng)
        }
        
        // For unknown airports, generate plausible coordinates
        // This is just for the demo - a real app would use accurate data
        let hash = code.utf8.reduce(0) { $0 &+ Int($1) }
        let lat = -60.0 + (Double(hash % 1200) / 10.0) // -60 to 60 degrees latitude
        let lng = -180.0 + (Double(hash % 3600) / 10.0) // -180 to 180 degrees longitude
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

// The main view for flight route visualization
struct FlightRouteVisualization: View {
    let flight: AeroFlight
    let airline: AirlineProfile?
    
    @State private var flightPositions: [FlightPosition] = []
    @State private var isLoadingPositions = true
    @State private var positionError: Error? = nil
    
    @State private var animatePosition = false
    @State private var animateProgress = false
    @State private var showWaypoints = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // World map background
                worldMapBackground
                
                if isLoadingPositions {
                    loadingView
                } else if let error = positionError {
                    errorView(error)
                } else if flightPositions.isEmpty {
                    noDataView
                } else {
                    // Flight path visualization
                    flightPathVisualization(in: geometry)
                }
            }
            .onAppear {
                loadFlightPositions()
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
        )
        .cornerRadius(16)
    }
    
    // Loading state view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading flight path...")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    // Error state view
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            
            Text("Unable to load flight path")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                loadFlightPositions()
            }) {
                Text("Try Again")
                    .font(.system(.body, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
    
    // No data state view
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.6))
            
            if flight.isInProgress {
                Text("No position data available yet")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Position updates typically appear shortly after takeoff")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Flight path not available")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                
                Text(flight.status)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                loadFlightPositions()
            }) {
                Text("Refresh")
                    .font(.system(.body, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
    
    // World map background
    private var worldMapBackground: some View {
        Image(systemName: "map")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.white.opacity(0.1))
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.cyan.opacity(0.2),
                        Color.purple.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    // Flight path visualization with real position data
    private func flightPathVisualization(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Draw the full flight path
            if flightPositions.count > 1 {
                flightPath
                    .stroke(
                        routeGradient,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [5, 3])
                    )
                    .opacity(0.7)
                
                // Progress path (solid) that shows how far the plane has traveled
                if flight.isInProgress {
                    flightPath
                        .trim(from: 0, to: animateProgress ? progressPercentage : 0)
                        .stroke(
                            routeGradient,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                }
            }
            
            // Draw the origin and destination points
            airportMarker(for: .origin)
                .position(originPosition)
            
            airportMarker(for: .destination)
                .position(destinationPosition)
            
            // Draw the current aircraft position if flight is in progress
            if flight.isInProgress {
                aircraftMarker
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                showWaypoints = true
            }
            
            withAnimation(.easeInOut(duration: 3.0)) {
                animatePosition = true
            }
            
            withAnimation(.easeInOut(duration: 3.5).delay(0.5)) {
                animateProgress = true
            }
        }
    }
    
    // Path for the flight route based on position data
    private var flightPath: Path {
        Path { path in
            guard let firstPosition = flightPositions.first else { return }
            
            path.move(to: CGPoint(
                x: longitudeToX(firstPosition.longitude),
                y: latitudeToY(firstPosition.latitude)
            ))
            
            for position in flightPositions.dropFirst() {
                path.addLine(to: CGPoint(
                    x: longitudeToX(position.longitude),
                    y: latitudeToY(position.latitude)
                ))
            }
        }
    }
    
    // Aircraft marker that shows current position
    private var aircraftMarker: some View {
        ZStack {
            // Pulsing circle behind aircraft
            Circle()
                .fill(aircraftColor.opacity(0.3))
                .frame(width: 30, height: 30)
                .pulseFlight(intensity: 0.5)
            
            // Aircraft icon
            Image(systemName: "airplane")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(aircraftColor)
                .rotationEffect(aircraftRotation)
                .airplaneMovement(intensity: 0.3)
        }
        .position(currentAircraftPosition)
    }
    
    // Marker for airports (origin or destination)
    private func airportMarker(for type: AirportType) -> some View {
        let color = type == .origin ? originColor : destinationColor
        let code = type == .origin ? flight.origin.displayCode : flight.destination.displayCode
        
        return ZStack {
            // Airport dot
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                
            // Airport code label
            Text(code)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .offset(y: -20)
        }
    }
    
    // Get aircraft rotation based on heading or route direction
    private var aircraftRotation: Angle {
        if let lastPosition = flightPositions.last, let heading = lastPosition.heading {
            return .degrees(Double(heading))
        }
        
        // Fallback to approximate heading based on route direction
        if flightPositions.count >= 2 {
            let lastPos = flightPositions.last!
            let secondLastPos = flightPositions[flightPositions.count - 2]
            
            let dLng = lastPos.longitude - secondLastPos.longitude
            let dLat = lastPos.latitude - secondLastPos.latitude
            let angle = atan2(dLng, dLat) * (180.0 / .pi)
            
            return .degrees(angle)
        }
        
        return .degrees(0)
    }
    
    // MARK: - Coordinate Conversion Helpers
    
    enum AirportType {
        case origin
        case destination
    }
    
    // Origin position based on the first position data point or airport data
    private var originPosition: CGPoint {
        if let firstPosition = flightPositions.first {
            return CGPoint(
                x: longitudeToX(firstPosition.longitude),
                y: latitudeToY(firstPosition.latitude)
            )
        }
        
        // Fallback to airport coordinates if no position data
        if let coordinates = FlightPositionService.shared.getCoordinatesForAirport(flight.origin.code) {
            return CGPoint(
                x: longitudeToX(coordinates.longitude),
                y: latitudeToY(coordinates.latitude)
            )
        }
        
        return CGPoint(x: 100, y: 200)
    }
    
    // Destination position based on the last position data point or airport data
    private var destinationPosition: CGPoint {
        if let lastPosition = flightPositions.last, !flight.isInProgress {
            return CGPoint(
                x: longitudeToX(lastPosition.longitude),
                y: latitudeToY(lastPosition.latitude)
            )
        }
        
        // Fallback to airport coordinates
        if let coordinates = FlightPositionService.shared.getCoordinatesForAirport(flight.destination.code) {
            return CGPoint(
                x: longitudeToX(coordinates.longitude),
                y: latitudeToY(coordinates.latitude)
            )
        }
        
        return CGPoint(x: 300, y: 200)
    }
    
    // Current aircraft position based on progress along the path
    private var currentAircraftPosition: CGPoint {
        guard !flightPositions.isEmpty else { return CGPoint(x: 200, y: 200) }
        
        if let lastPosition = flightPositions.last {
            return CGPoint(
                x: longitudeToX(lastPosition.longitude),
                y: latitudeToY(lastPosition.latitude)
            )
        }
        
        return originPosition
    }
    
    // Convert longitude to X coordinate
    private func longitudeToX(_ longitude: Double) -> CGFloat {
        // Find min/max longitudes
        let minLon = flightPositions.map { $0.longitude }.min() ?? -180.0
        let maxLon = flightPositions.map { $0.longitude }.max() ?? 180.0
        
        // Add padding
        let paddedMinLon = minLon - (maxLon - minLon) * 0.1
        let paddedMaxLon = maxLon + (maxLon - minLon) * 0.1
        
        // Ensure minimum width for very short routes
        let width = max(paddedMaxLon - paddedMinLon, 5.0)
        let paddedWidth = UIScreen.main.bounds.width * 0.8
        
        return CGFloat((longitude - paddedMinLon) / width) * paddedWidth + (UIScreen.main.bounds.width * 0.1)
    }
    
    // Convert latitude to Y coordinate
    private func latitudeToY(_ latitude: Double) -> CGFloat {
        // Find min/max latitudes
        let minLat = flightPositions.map { $0.latitude }.min() ?? -90.0
        let maxLat = flightPositions.map { $0.latitude }.max() ?? 90.0
        
        // Add padding
        let paddedMinLat = minLat - (maxLat - minLat) * 0.1
        let paddedMaxLat = maxLat + (maxLat - minLat) * 0.1
        
        // Ensure minimum height for very short routes
        let height = max(paddedMaxLat - paddedMinLat, 5.0)
        let paddedHeight = UIScreen.main.bounds.width * 0.5 // Maintain aspect ratio
        
        // Note: Y increases downward in SwiftUI, so we invert the calculation
        return CGFloat(1.0 - (latitude - paddedMinLat) / height) * paddedHeight + (UIScreen.main.bounds.width * 0.05)
    }
    
    // MARK: - Styling Properties
    
    // Gradient for the route path
    private var routeGradient: LinearGradient {
        if let airline = airline, let code = airline.icaoCode ?? airline.iataCode {
            return AirlineTheme.gradient(for: code)
        }
        
        return LinearGradient(
            gradient: Gradient(colors: [.blue, .purple]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Progress percentage for animating the path
    private var progressPercentage: CGFloat {
        return CGFloat(flight.accurateProgressPercent) / 100.0
    }
    
    // Colors for origin, destination, and aircraft
    private var originColor: Color {
        if let airline = airline, let code = airline.icaoCode ?? airline.iataCode {
            return AirlineTheme.colors(for: code).primary
        }
        return .blue
    }
    
    private var destinationColor: Color {
        if let airline = airline, let code = airline.icaoCode ?? airline.iataCode {
            return AirlineTheme.colors(for: code).secondary
        }
        return .purple
    }
    
    private var aircraftColor: Color {
        if let airline = airline, let code = airline.icaoCode ?? airline.iataCode {
            return AirlineTheme.colors(for: code).primary
        }
        return .white
    }
    
    // MARK: - Data Loading
    
    // Load flight positions from the API
    private func loadFlightPositions() {
        isLoadingPositions = true
        positionError = nil
        
        Task {
            do {
                // Try to get positions from AeroAPI
                let positions = try await FlightPositionService.shared.fetchFlightPositions(for: flight)
                
                await MainActor.run {
                    flightPositions = positions.sorted { $0.timestamp < $1.timestamp }
                    isLoadingPositions = false
                }
            } catch {
                await MainActor.run {
                    positionError = error
                    isLoadingPositions = false
                }
            }
        }
    }
}

// Preview
struct FlightRouteVisualization_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock flight for preview
        let mockFlight = createMockFlight(
            ident: "UAL1234",
            operator_: "United Airlines",
            operatorIcao: "UAL",
            origin: createMockAirport(code: "SFO", city: "San Francisco"),
            destination: createMockAirport(code: "JFK", city: "New York"),
            progressPercent: 65
        )
        
        let mockAirline = AirlineProfile(
            name: "United Airlines",
            shortName: "United",
            iataCode: "UA",
            icaoCode: "UAL",
            callsign: "UNITED",
            country: "United States",
            location: "Chicago, Illinois",
            website: "https://www.united.com"
        )
        
        return ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            FlightRouteVisualization(flight: mockFlight, airline: mockAirline)
                .padding()
        }
    }
    
    // Helper for creating mock data for previews
    static func createMockFlight(
        ident: String,
        operator_: String,
        operatorIcao: String?,
        origin: AeroAirport,
        destination: AeroAirport,
        progressPercent: Int
    ) -> AeroFlight {
        return AeroFlight(
            ident: ident,
            identIcao: nil,
            identIata: nil,
            faFlightId: "1234567",
            operator_: operator_,
            operatorIcao: operatorIcao,
            operatorIata: nil,
            flightNumber: "1234",
            registration: nil,
            atcIdent: nil,
            inboundFaFlightId: nil,
            codeshares: nil,
            codeshares_iata: nil,
            origin: origin,
            destination: destination,
            departureDelay: nil,
            arrivalDelay: nil,
            filedEte: nil,
            progressPercent: progressPercent,
            status: "en route",
            aircraftType: "B738",
            routeDistance: 2500,
            filedAirspeed: 450,
            filedAltitude: 35000,
            route: nil,
            baggageClaim: nil,
            gateOrigin: nil,
            gateDestination: nil,
            terminalOrigin: nil,
            terminalDestination: nil,
            flightType: .airline,
            scheduledOut: ISO8601DateFormatter().string(from: Date()),
            estimatedOut: nil,
            actualOut: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-2 * 3600)),
            scheduledOff: nil,
            estimatedOff: nil,
            actualOff: nil,
            scheduledOn: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3 * 3600)),
            estimatedOn: nil,
            actualOn: nil,
            scheduledIn: nil,
            estimatedIn: nil,
            actualIn: nil,
            diverted: false,
            cancelled: false,
            blocked: false,
            positionOnly: false
        )
    }
    
    static func createMockAirport(code: String, city: String?) -> AeroAirport {
        return AeroAirport(
            code: code,
            codeIcao: nil,
            codeIata: code,
            timezone: "America/Los_Angeles",
            name: "\(city ?? code) International Airport",
            city: city
        )
    }
}
