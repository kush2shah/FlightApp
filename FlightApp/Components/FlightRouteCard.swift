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
    
    private var formattedRoute: String {
        // Handle route display carefully
        guard let route = flight.route, !route.isEmpty else {
            return "Route information not available"
        }
        
        let components = route.split(separator: " ")
        
        // If route is very long, just show a few key waypoints
        if components.count > 10 {
            let keyWaypoints: [Substring] = [
                components.first ?? "",
                components[components.count / 2],
                components.last ?? ""
            ]
            return keyWaypoints.map { String($0) }.joined(separator: " ... ")
        }
        
        return route
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Origin and Destination Information
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
            
            // Flight Timeline
            FlightTimelineView(flight: flight, times: times)
            
            // Route Details (if available and meaningful)
            if formattedRoute != "Route information not available" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Route")
                        .font(.headline)
                    
                    Text(formattedRoute)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct FlightTimelineView: View {
    let flight: AeroFlight
    let times: (departure: String, arrival: String)
    
    private var departureStatus: (icon: String, color: Color) {
        // Significant delay is more than 15 minutes
        if let departureDelay = flight.departureDelay, departureDelay > 900 {
            return ("timer", .orange)
        }
        
        // If flight has departed
        if flight.actualOff != nil {
            return ("checkmark.circle.fill", .green)
        }
        
        // Scheduled but not yet departed
        return ("clock", .blue)
    }
    
    private var arrivalStatus: (icon: String, color: Color) {
        // Significant delay is more than 15 minutes
        if let arrivalDelay = flight.arrivalDelay, arrivalDelay > 900 {
            return ("timer", .orange)
        }
        
        // If flight has arrived
        if flight.actualOn != nil {
            return ("checkmark.circle.fill", .green)
        }
        
        // In-progress or not yet arrived
        if flight.actualOff != nil && flight.actualOn == nil {
            return ("airplane", .blue)
        }
        
        // Scheduled but not yet departed
        return ("clock", .blue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
            
            HStack(spacing: 15) {
                // Departure Status
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: departureStatus.icon)
                        .foregroundColor(departureStatus.color)
                    
                    Text("Departure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(times.departure)
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Flight Progress
                if flight.actualOff != nil && flight.actualOn == nil {
                    VStack {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 10)
                                
                                // Progress indicator
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                                    .frame(width: CGFloat(flight.accurateProgressPercent) / 100 * geometry.size.width, height: 10)
                            }
                        }
                        .frame(height: 10)
                        
                        Text("\(flight.accurateProgressPercent)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Arrival Status
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: arrivalStatus.icon)
                        .foregroundColor(arrivalStatus.color)
                    
                    Text("Arrival")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(times.arrival)
                        .font(.subheadline)
                }
            }
        }
    }
}

#Preview {
    Text("Preview not supported")
}
