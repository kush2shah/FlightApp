//
//  FlightHeroSection.swift
//  FlightApp
//
//  Created by Kush Shah on 8/20/25.
//

import SwiftUI

struct FlightHeroSection: View {
    let flight: AeroFlight
    
    private var statusInfo: (text: String, color: Color, icon: String, showProgress: Bool) {
        if flight.cancelled {
            return ("Cancelled", .red, "xmark.circle.fill", false)
        }
        
        // Arrived status
        if flight.actualOn != nil {
            if let arrivalDelay = flight.arrivalDelay {
                if arrivalDelay > 900 { // 15+ minutes late
                    let minutes = arrivalDelay / 60
                    return ("Arrived \(minutes)m Late", .orange, "checkmark.circle.fill", false)
                } else if arrivalDelay < -300 { // 5+ minutes early
                    let minutes = abs(arrivalDelay) / 60
                    return ("Arrived \(minutes)m Early", .green, "checkmark.circle.fill", false)
                }
            }
            return ("Arrived", .green, "checkmark.circle.fill", false)
        }
        
        // In flight status
        if flight.isInProgress {
            if let arrivalDelay = flight.arrivalDelay, arrivalDelay > 900 {
                let minutes = arrivalDelay / 60
                return ("En Route • \(minutes)m Late", .orange, "airplane", true)
            }
            return ("En Route", .green, "airplane", true)
        }
        
        // Pre-departure status
        if let departureDelay = flight.departureDelay, departureDelay > 0 {
            let minutes = departureDelay / 60
            if minutes >= 30 {
                return ("Delayed \(minutes)m", .red, "exclamationmark.triangle.fill", false)
            } else {
                return ("Delayed \(minutes)m", .orange, "clock.fill", false)
            }
        }
        
        if let scheduledOut = flight.scheduledOut,
           let date = ISO8601DateFormatter().date(from: scheduledOut),
           date > Date() {
            return ("Scheduled", .blue, "clock", false)
        }
        
        return ("On Time", .green, "checkmark.circle", false)
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
                VStack(alignment: .trailing, spacing: 4) {
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
                    
                    // Progress indicator for in-flight
                    if statusInfo.showProgress {
                        Text("\(flight.accurateProgressPercent)% complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Prominent delay warning for pre-departure flights
            if let departureDelay = flight.departureDelay, 
               departureDelay > 600, // 10+ minutes
               flight.actualOff == nil { // hasn't departed yet
                let minutes = departureDelay / 60
                
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Departure delayed by \(minutes) minutes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
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