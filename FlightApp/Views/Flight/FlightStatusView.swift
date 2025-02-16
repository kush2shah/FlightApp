//
//  FlightStatusView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/12/25.
//

import SwiftUI

extension Font {
    static func sfRounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
}

struct FlightStatusView: View {
    let flight: AeroFlight
    
    private var timeUntilFlight: (String, Color)? {
        guard let scheduledDeparture = flight.scheduledOut.flatMap({ ISO8601DateFormatter().date(from: $0) }) else {
            return nil
        }
        
        let now = Date()
        let timeInterval = scheduledDeparture.timeIntervalSince(now)
        
        // Don't show for past flights
        guard timeInterval > 0 else {
            return nil
        }
        
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        // Format the time remaining
        let timeString: String
        let color: Color
        
        switch hours {
        case 0:
            timeString = "\(minutes)m until departure"
            color = minutes < 30 ? .orange : .blue
        case 1:
            timeString = "1h \(minutes)m until departure"
            color = .blue
        default:
            timeString = "\(hours)h until departure"
            color = .blue
        }
        
        return (timeString, color)
    }
    
    private var statusDetails: (icon: String, color: Color, message: String) {
        if flight.cancelled {
            return ("xmark.circle.fill", .red, "Cancelled")
        }
        
        if flight.diverted {
            return ("exclamationmark.triangle.fill", .orange, "Diverted")
        }
        
        // For arrived flights
        if flight.actualOn != nil {
            if let delay = flight.arrivalDelay {
                if delay > 0 {
                    return ("checkmark.circle.fill", .orange, "Arrived \(delay.formattedDelay()) late")
                } else if delay < 0 {
                    return ("checkmark.circle.fill", .green, "Arrived \(abs(delay).formattedDelay()) early")
                }
            }
            return ("checkmark.circle.fill", .green, "Arrived on time")
        }
        
        let hasSignificantDepartureDelay = (flight.departureDelay ?? 0) > 900
        let hasSignificantArrivalDelay = (flight.arrivalDelay ?? 0) > 900
        
        if flight.actualOff != nil && flight.actualOn == nil {
            if hasSignificantDepartureDelay || hasSignificantArrivalDelay {
                return ("timer", .orange, "Delayed")
            }
            return ("airplane", .green, "In Flight")
        }
        
        if flight.status.lowercased().contains("scheduled") {
            return ("clock", .blue, "Scheduled")
        }
        
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
                        .font(.sfRounded(size: 18, weight: .semibold))
                        .foregroundColor(statusDetails.color)
                    
                    if let (timeString, timeColor) = timeUntilFlight {
                        Text(timeString)
                            .font(.sfRounded(size: 15, weight: .medium))
                            .foregroundColor(timeColor)
                    }
                    
                    if let departureDelay = flight.departureDelay, departureDelay > 0 {
                        Text("Departure Delayed by \(formatDelay(departureDelay))")
                            .font(.sfRounded(size: 15))
                            .foregroundColor(.orange)
                    }
                    
                    if let arrivalDelay = flight.arrivalDelay, arrivalDelay > 0 {
                        Text("Arrival Delayed by \(formatDelay(arrivalDelay))")
                            .font(.sfRounded(size: 15))
                            .foregroundColor(.orange)
                    }
                }
            }
            
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
                .font(.sfRounded(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.sfRounded(size: 15, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    Text("Preview not supported")
}
