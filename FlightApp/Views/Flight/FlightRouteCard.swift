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
        VStack(spacing: 24) {
            // Route information with progress
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    RouteEndpoint(
                        code: flight.origin.displayCode,
                        name: flight.origin.city ?? flight.origin.name ?? "Unknown"
                    )
                    
                    Spacer()
                    
                    // Progress bar
                    if flight.isInProgress {
                        customProgressBar
                    }
                    
                    Spacer()
                    
                    RouteEndpoint(
                        code: flight.destination.displayCode,
                        name: flight.destination.city ?? flight.destination.name ?? "Unknown"
                    )
                }
                
                // Flight duration
                if let filed = flight.filedEte {
                    flightDurationView(duration: filed)
                }
            }
            
            // Time information
            HStack(spacing: 16) {
                FlightTimeView(time: times.departure, isArrival: false)
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                FlightTimeView(time: times.arrival, isArrival: true)
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
                    .fill(progressColor)
                    .frame(width: progressWidth(in: geometry), height: 2)
                
                // Airplane icon
                Image(systemName: "airplane")
                    .foregroundStyle(progressColor)
                    .rotationEffect(.degrees(0))
                    .offset(x: progressWidth(in: geometry) - 10)
            }
        }
        .frame(height: 20)
    }
    
    // Dynamic progress color based on flight status
    private var progressColor: Color {
        return .blue
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

private struct RouteEndpoint: View {
    let code: String
    let name: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(code)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    Text("Preview not supported")
}
