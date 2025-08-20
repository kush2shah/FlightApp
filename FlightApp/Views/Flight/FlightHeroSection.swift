//
//  FlightHeroSection.swift
//  FlightApp
//
//  Created by Kush Shah on 2/20/25.
//

import SwiftUI

struct FlightHeroSection: View {
    let flight: AeroFlight
    
    private var statusInfo: (text: String, color: Color, icon: String) {
        if flight.cancelled {
            return ("Cancelled", .red, "xmark.circle.fill")
        }
        
        if flight.isInProgress {
            return ("In Flight", .green, "airplane.circle.fill")
        }
        
        if let departureDelay = flight.departureDelay, departureDelay > 0 {
            let minutes = departureDelay / 60
            return ("Delayed \(minutes)m", .orange, "clock.fill")
        }
        
        if flight.actualOn != nil {
            return ("Arrived", .green, "checkmark.circle.fill")
        }
        
        if let scheduledOut = flight.scheduledOut,
           let date = ISO8601DateFormatter().date(from: scheduledOut),
           date > Date() {
            return ("Scheduled", .blue, "clock")
        }
        
        return ("On Time", .green, "checkmark.circle")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Flight identifier with date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.operatorIata ?? flight.operator_ ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(flight.flightNumber ?? flight.ident)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Subtle date display
                    if let scheduledOut = flight.scheduledOut,
                       let date = ISO8601DateFormatter().date(from: scheduledOut),
                       let timezone = TimeZone(identifier: flight.origin.timezone ?? "UTC") {
                        Text(date.smartRelativeDate(in: timezone))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status badge
                HStack(spacing: 6) {
                    Image(systemName: statusInfo.icon)
                        .font(.caption)
                    Text(statusInfo.text)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusInfo.color.opacity(0.15))
                .foregroundColor(statusInfo.color)
                .cornerRadius(8)
            }
            
            // Route
            HStack {
                RouteEndpoint(
                    code: flight.origin.displayCode,
                    name: flight.origin.city ?? flight.origin.name ?? "Unknown"
                )
                
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "airplane")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if let distance = flight.routeDistance {
                        Text("\(distance) mi")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                RouteEndpoint(
                    code: flight.destination.displayCode,
                    name: flight.destination.city ?? flight.destination.name ?? "Unknown"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    Text("Preview requires AeroFlight data")
}