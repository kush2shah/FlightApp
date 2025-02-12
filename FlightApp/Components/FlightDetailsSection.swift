//
//  FlightDetailsSection.swift
//  FlightApp
//
//  Created by Kush Shah on 2/11/25.
//

import SwiftUI

struct FlightDetailsSection: View {
    let flight: AeroFlight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Gate Information
            if flight.gateOrigin != nil || flight.gateDestination != nil {
                GateInformationCard(flight: flight)
            }
            
            // Flight Details
            if let distance = flight.routeDistance {
                FlightInformationCard(flight: flight, distance: distance)
            }
        }
        .padding(.horizontal)
    }
}

struct GateInformationCard: View {
    let flight: AeroFlight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gate Information")
                .font(.headline)
            
            HStack {
                if let gate = flight.gateOrigin {
                    VStack(alignment: .leading) {
                        Text("Departure")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Gate \(gate)")
                            .font(.title3)
                    }
                }
                
                Spacer()
                
                if let gate = flight.gateDestination {
                    VStack(alignment: .trailing) {
                        Text("Arrival")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Gate \(gate)")
                            .font(.title3)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct FlightInformationCard: View {
    let flight: AeroFlight
    let distance: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flight Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                DetailRow(icon: "map", title: "Distance", value: "\(distance) mi")
                
                if let speed = flight.filedAirspeed {
                    DetailRow(icon: "speedometer", title: "Speed", value: "\(speed) kts")
                }
                
                if let altitude = flight.filedAltitude {
                    DetailRow(icon: "arrow.up.and.down", title: "Altitude", value: "FL\(altitude)")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

