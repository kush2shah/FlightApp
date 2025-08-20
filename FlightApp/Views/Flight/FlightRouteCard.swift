//
//  FlightRouteCard.swift
//  FlightApp
//
//  Created by Kush Shah on 2/11/25.
//

import SwiftUI

struct FlightRouteCard: View {
    let flight: AeroFlight
    let times: (departure: FlightTime, arrival: FlightTime)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Route Header
            HStack {
                RouteEndpoint(
                    code: flight.origin.displayCode,
                    name: flight.origin.city ?? flight.origin.name ?? "Unknown"
                )
                
                Spacer()
                
                RouteEndpoint(
                    code: flight.destination.displayCode,
                    name: flight.destination.city ?? flight.destination.name ?? "Unknown"
                )
            }
            
            // Progress Bar
            if flight.isInProgress {
                customProgressBar
            }
            
            // Time Information
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Departure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    FlightTimeView(time: times.departure, isArrival: false)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Arrival")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    FlightTimeView(time: times.arrival, isArrival: true)
                }
            }
            
            // Show date context only when departure and arrival are on different dates
            if times.departure.relativeDate != times.arrival.relativeDate {
                HStack {
                    Text(times.departure.relativeDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(times.arrival.relativeDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            
            // Flight Duration
            if let filed = flight.filedEte {
                flightDurationView(duration: filed)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    // Custom progress bar
    private var customProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 2)
                
                // Progress fill
                Rectangle()
                    .fill(.blue)
                    .frame(width: progressWidth(in: geometry), height: 2)
                
                // Airplane icon
                Image(systemName: "airplane")
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(0))
                    .offset(x: progressWidth(in: geometry) - 10)
            }
        }
        .frame(height: 20)
    }
    
    // Calculate progress width based on available geometry
    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        let progressRatio = CGFloat(flight.accurateProgressPercent) / 100.0
        return geometry.size.width * progressRatio
    }
    
    // Flight duration view
    private func flightDurationView(duration: Int) -> some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            
            Text(formattedDuration(duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Format flight duration from seconds to hours and minutes
    private func formattedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct RouteEndpoint: View {
    let code: String
    let name: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(code)
                .font(.sfRounded(size: 17, weight: .bold))
            
            Text(name)
                .font(.sfRounded(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    Text("Preview not supported")
}
