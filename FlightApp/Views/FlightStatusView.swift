//
//  FlightStatusView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/12/25.
//

import SwiftUI

struct FlightStatusView: View {
    let flight: AeroFlight
    
    private var statusDetails: (icon: String, color: Color, message: String) {
        // Determine status based on multiple factors
        if flight.cancelled {
            return ("xmark.circle.fill", .red, "Cancelled")
        }
        
        if flight.diverted {
            return ("exclamationmark.triangle.fill", .orange, "Diverted")
        }
        
        // Check for delays
        let hasSignificantDepartureDelay = (flight.departureDelay ?? 0) > 900 // 15 minutes
        let hasSignificantArrivalDelay = (flight.arrivalDelay ?? 0) > 900 // 15 minutes
        
        // In-progress flight states
        if flight.actualOff != nil && flight.actualOn == nil {
            if hasSignificantDepartureDelay || hasSignificantArrivalDelay {
                return ("timer", .orange, "Delayed")
            }
            return ("airplane", .green, "In Flight")
        }
        
        // Completed flight states
        if flight.actualOn != nil {
            if hasSignificantArrivalDelay {
                return ("timer", .orange, "Arrived (Delayed)")
            }
            return ("checkmark.circle.fill", .green, "Arrived")
        }
        
        // Scheduled flight states
        if flight.status.lowercased().contains("scheduled") {
            return ("clock", .blue, "Scheduled")
        }
        
        // Fallback
        return ("info.circle", .secondary, flight.status.capitalized)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: statusDetails.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(statusDetails.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusDetails.message)
                        .font(.headline)
                        .foregroundColor(statusDetails.color)
                    
                    // Detailed delay information
                    if let departureDelay = flight.departureDelay, departureDelay > 0 {
                        Text("Departure Delayed by \(formatDelay(departureDelay))")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    if let arrivalDelay = flight.arrivalDelay, arrivalDelay > 0 {
                        Text("Arrival Delayed by \(formatDelay(arrivalDelay))")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Additional Status Details
            additionalStatusDetails
        }
        .padding()
        .background(statusDetails.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var additionalStatusDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let registration = flight.registration {
                DetailRow(icon: "number", title: "Aircraft", value: registration)
            }
            
            if let aircraftType = flight.aircraftType {
                DetailRow(icon: "airplane.circle", title: "Aircraft Type", value: aircraftType)
            }
        }
    }
    
    private func formatDelay(_ delay: Int) -> String {
        let hours = delay / 3600
        let minutes = (delay % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    Text("Preview not supported")
}
