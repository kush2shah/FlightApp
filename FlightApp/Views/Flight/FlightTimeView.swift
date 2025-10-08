//
//  FlightTimeView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/12/25.
//

import SwiftUI

struct FlightTimeView: View {
    let time: FlightTime
    let isArrival: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Main time display with comparison
            VStack(alignment: .leading, spacing: 2) {
                mainTimeDisplay
                comparisonTimeDisplay
            }
            
            Spacer()
            
            // Status indicator
            statusBadge
        }
        .padding(8)
        .background(backgroundStyle)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(overlayColor, lineWidth: 1)
        )
    }
    
    // Main time display with actual or estimated time
    private var mainTimeDisplay: some View {
            Group {
                if let actualTime = time.actualTime {
                    Text(actualTime)
                        .font(.sfRounded(size: 16, weight: .bold))
                        .foregroundColor(primaryTimeColor)
                        .fixedSize(horizontal: true, vertical: false)
                }
                else {
                    Text(time.estimatedTime ?? time.scheduledTime ?? "--:--")
                        .font(.sfRounded(size: 16, weight: .bold))
                        .foregroundColor(primaryTimeColor)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        
        private var comparisonTimeDisplay: some View {
            Group {
                if let actualTime = time.actualTime,
                   let scheduledTime = time.scheduledTime,
                   actualTime != scheduledTime {
                    Text(scheduledTime)
                        .font(.sfRounded(size: 13))
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
                else if let estimatedTime = time.estimatedTime,
                        let scheduledTime = time.scheduledTime,
                        estimatedTime != scheduledTime {
                    Text(scheduledTime)
                        .font(.sfRounded(size: 13))
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
            }
        }
    
    
    // Status badge showing early/delayed information
    private var statusBadge: some View {
        Group {
            if let difference = time.minutesDifference {
                HStack(spacing: 4) {
                    Image(systemName: time.isEarly ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .foregroundColor(time.isEarly ? .green : .red)
                    
                    Text("\(difference)m \(time.isEarly ? "Early" : "Delayed")")
                        .font(.caption)
                        .foregroundColor(time.isEarly ? .green : .red)
                }
            }
        }
    }
    
    // Dynamic color based on time status
    private var primaryTimeColor: Color {
        if time.cancelled {
            return .red
        }
        
        // Prioritize delay indication for departure
        if time.isDelayed {
            return .red
        }
        
        if time.isEarly {
            return .green
        }
        
        return .primary
    }
    
    // Background style based on flight status
    private var backgroundStyle: Color {
        if time.cancelled {
            return Color.red.opacity(0.1)
        }
        
        if time.isDelayed {
            return Color.red.opacity(0.1)
        }
        
        if time.isEarly {
            return Color.green.opacity(0.1)
        }
        
        return Color.secondary.opacity(0.05)
    }
    
    // Overlay color based on flight status
    private var overlayColor: Color {
        if time.cancelled {
            return Color.red.opacity(0.3)
        }
        
        if time.isDelayed {
            return Color.red.opacity(0.3)
        }
        
        if time.isEarly {
            return Color.green.opacity(0.3)
        }
        
        return Color.clear
    }
}

#Preview {
    VStack {
        // Early departure
        FlightTimeView(
            time: FlightTime(
                displayTime: "14:30",
                displayTimezone: "EST",
                actualTime: "14:25",
                scheduledTime: "14:30",
                estimatedTime: "14:35",
                date: "Mar 15",
                fullDate: Date(),
                timezone: TimeZone(identifier: "EST"),
                isEarly: true,
                isDelayed: false,
                minutesDifference: 5,
                cancelled: false
            ),
            isArrival: false
        )
        
        // Delayed departure
        FlightTimeView(
            time: FlightTime(
                displayTime: "16:45",
                displayTimezone: "PST",
                actualTime: nil,
                scheduledTime: "16:30",
                estimatedTime: "16:45",
                date: "Mar 15",
                fullDate: Date(),
                timezone: TimeZone(identifier: "PST"),
                isEarly: false,
                isDelayed: true,
                minutesDifference: 15,
                cancelled: false
            ),
            isArrival: false
        )
        
        // Delayed arrival
        FlightTimeView(
            time: FlightTime(
                displayTime: "16:45",
                displayTimezone: "PST",
                actualTime: nil,
                scheduledTime: "16:30",
                estimatedTime: "16:45",
                date: "Mar 15",
                fullDate: Date(),
                timezone: TimeZone(identifier: "PST"),
                isEarly: false,
                isDelayed: true,
                minutesDifference: 15,
                cancelled: false
            ),
            isArrival: true
        )
    }
}
