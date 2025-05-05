//
//  FlightProgressView.swift
//  FlightApp
//
//  Created by Kush Shah on 5/4/25.
//

import SwiftUI

struct FlightProgressView: View {
    let flight: AeroFlight
    let airline: AirlineProfile?
    
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Flight path visualization
            ZStack {
                // Background path
                flightPathShape
                    .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(height: 100)
                
                // Progress path with airline theme
                flightPathShape
                    .trim(from: 0, to: CGFloat(flight.accurateProgressPercent) / 100.0)
                    .stroke(
                        airlineGradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(height: 100)
                
                // Airplane icon that follows the path
                planeIcon
                    .offset(y: -10) // Offset to position plane above the path
            }
            .padding(.horizontal)
            
            // Progress information
            progressInfo
        }
        .onAppear {
            // Animate progress when view appears
            withAnimation(.easeInOut(duration: 1.5)) {
                animationProgress = CGFloat(flight.accurateProgressPercent) / 100.0
            }
        }
    }
    
    // Create a curved path representing the flight route
    private var flightPathShape: Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 50))
            
            // Create a curved path that rises and falls
            path.addCurve(
                to: CGPoint(x: UIScreen.main.bounds.width - 32, y: 50),
                control1: CGPoint(x: UIScreen.main.bounds.width * 0.3, y: 0),
                control2: CGPoint(x: UIScreen.main.bounds.width * 0.7, y: 0)
            )
        }
    }
    
    // Airplane icon that moves along the path based on progress
    private var planeIcon: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let progressPosition = width * animationProgress
            
            Image(systemName: "airplane")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(primaryAirlineColor)
                .rotationEffect(.degrees(-10)) // Tilt plane slightly upward
                .position(x: progressPosition, y: 50)
                .animation(.easeInOut(duration: 1.5), value: animationProgress)
        }
    }
    
    // Progress information section
    private var progressInfo: some View {
        HStack(spacing: 16) {
            // Origin Airport
            VStack(alignment: .leading) {
                Text(flight.origin.displayCode)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                if let city = flight.origin.city {
                    Text(city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Flight progress
            VStack {
                Text("\(flight.accurateProgressPercent)%")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(primaryAirlineColor)
                
                Text("Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Destination Airport
            VStack(alignment: .trailing) {
                Text(flight.destination.displayCode)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                if let city = flight.destination.city {
                    Text(city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // Use airline theming for gradient or fall back to default
    private var airlineGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: airlineColors),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var airlineColors: [Color] {
        if let airline = airline, let code = airline.icaoCode ?? airline.iataCode {
            let theme = AirlineTheme.colors(for: code)
            return [theme.primary, theme.secondary]
        } else if let code = flight.operatorIcao ?? flight.operatorIata {
            let theme = AirlineTheme.colors(for: code)
            return [theme.primary, theme.secondary]
        } else {
            return [.blue, .indigo]
        }
    }

    private var primaryAirlineColor: Color {
        airlineColors.first ?? .blue
    }
}

struct FlightProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFlight = PreviewData.createMockFlight(
            ident: "UAL1234",
            operator_: "United Airlines",
            operatorIcao: "UAL",
            origin: PreviewData.createMockAirport(code: "SFO", city: "San Francisco"),
            destination: PreviewData.createMockAirport(code: "JFK", city: "New York"),
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
        
        return FlightProgressView(flight: mockFlight, airline: mockAirline)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

// Helper for creating mock data for previews
private struct PreviewData {
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
