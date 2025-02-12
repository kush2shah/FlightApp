//
//  FlightRouteCard.swift
//  FlightApp
//
//  Created by Kush Shah on 2/11/25.
//

import SwiftUI

struct FlightRouteCard: View {
    let flight: AeroFlight
    let times: (departure: String, arrival: String)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Origin and Destination
            HStack {
                VStack(alignment: .leading) {
                    Text(flight.origin.displayCode)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(flight.origin.city ?? flight.origin.name ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(flight.destination.displayCode)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(flight.destination.city ?? flight.destination.name ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Visualization
            if flight.isInProgress {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: Double(flight.accurateProgressPercent), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    HStack {
                        Text("Departure: \(times.departure)")
                        Spacer()
                        Text("Arrival: \(times.arrival)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            } else {
                // Scheduled flight details
                HStack {
                    Text("Departure: \(times.departure)")
                    Spacer()
                    Text("Arrival: \(times.arrival)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}
