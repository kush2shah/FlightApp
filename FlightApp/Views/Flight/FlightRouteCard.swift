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
            
            // Progress Bar and Status
            flightProgressSection
            
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
    
    // Flight progress section with status
    private var flightProgressSection: some View {
        VStack(spacing: 8) {
            if flight.isInProgress {
                // Progress bar for in-flight
                customProgressBar
                
                // Arrival delay info for in-flight
                if let arrivalDelay = flight.arrivalDelay, abs(arrivalDelay) > 300 {
                    arrivalDelayView(delay: arrivalDelay)
                }
            } else if flight.actualOn != nil {
                // Completed flight status
                completedFlightStatus
            } else {
                // Pre-departure status
                preDepartureStatus
            }
        }
    }
    
    // Arrival delay view for in-flight
    private func arrivalDelayView(delay: Int) -> some View {
        let minutes = abs(delay) / 60
        let isLate = delay > 0
        
        return HStack(spacing: 6) {
            Image(systemName: isLate ? "clock.arrow.circlepath" : "speedometer")
                .font(.caption)
                .foregroundColor(isLate ? .orange : .green)
            
            Text(isLate ? "Arriving \(minutes)m late" : "Arriving \(minutes)m early")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isLate ? .orange : .green)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isLate ? Color.orange : Color.green).opacity(0.1))
        .cornerRadius(6)
    }
    
    // Completed flight status
    private var completedFlightStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text("Flight Completed")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
            
            Spacer()
            
            if let arrivalDelay = flight.arrivalDelay, abs(arrivalDelay) > 300 {
                let minutes = abs(arrivalDelay) / 60
                let isLate = arrivalDelay > 0
                Text(isLate ? "\(minutes)m late" : "\(minutes)m early")
                    .font(.caption)
                    .foregroundColor(isLate ? .orange : .green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
    }
    
    // Pre-departure status
    private var preDepartureStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text("Scheduled for Departure")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
    
    // Custom progress bar
    private var customProgressBar: some View {
        VStack(spacing: 4) {
            // Progress percentage
            HStack {
                Text("\(flight.accurateProgressPercent)% of flight completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress fill
                    Rectangle()
                        .fill(.blue)
                        .frame(width: progressWidth(in: geometry), height: 4)
                        .cornerRadius(2)
                    
                    // Airplane icon
                    Image(systemName: "airplane")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.blue)
                        .offset(x: max(0, progressWidth(in: geometry) - 6))
                }
            }
            .frame(height: 16)
        }
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
