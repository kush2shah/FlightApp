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
        VStack(spacing: 24) {
            // Route Information
            HStack {
                VStack(alignment: .leading) {
                    Text(flight.origin.code)
                        .font(.system(size: 32, weight: .bold))
                    Text(flight.origin.city ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(flight.destination.code)
                        .font(.system(size: 32, weight: .bold))
                    Text(flight.destination.city ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Flight Progress
            if let progress = flight.progressPercent {
                ProgressView(value: Double(progress), total: 100)
                    .tint(.blue)
            }
            
            // Times
            HStack {
                VStack(alignment: .leading) {
                    Text(times.departure)
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("Departure")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let duration = flight.filedEte {
                    Text("\(duration / 3600)h \((duration % 3600) / 60)m")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(times.arrival)
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("Arrival")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}
