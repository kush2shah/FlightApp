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
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                // Main time display
                VStack(alignment: .leading, spacing: 2) {
                    mainTimeDisplay
                    
                    // Status description
                    if let status = time.statusDescription {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                // Timezone
                Text(time.displayTimezone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(backgroundStyle)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(overlayColor, lineWidth: 1)
        )
    }
    
    // Main time display with emphasis and strikethrough
    private var mainTimeDisplay: some View {
        Group {
            // Arrival view might show estimated vs scheduled
            if isArrival, let estimatedTime = time.estimatedTime,
               let scheduledTime = time.scheduledTime,
               estimatedTime != scheduledTime {
                HStack(spacing: 8) {
                    Text(estimatedTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTimeColor)
                    
                    Text(scheduledTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .strikethrough(true, color: .red)
                }
            }
            // Departure view shows actual vs scheduled
            else if let actualTime = time.actualTime,
                    let scheduledTime = time.scheduledTime,
                    actualTime != scheduledTime {
                HStack(spacing: 8) {
                    Text(actualTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTimeColor)
                    
                    Text(scheduledTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .strikethrough(true, color: .red)
                }
            }
            // Fallback to single time display
            else {
                Text(time.displayTime)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTimeColor)
            }
        }
    }
    
    // Color for primary time based on status
    private var primaryTimeColor: Color {
        if time.cancelled {
            return .red
        }
        if time.isEarly {
            return .green
        }
        if time.isDelayed {
            return .red
        }
        return .primary
    }
    
    // Status color
    private var statusColor: Color {
        if time.isEarly {
            return .green
        }
        if time.isDelayed {
            return .red
        }
        return .secondary
    }
    
    // Background style based on flight status
    private var backgroundStyle: Color {
        if time.cancelled {
            return Color.red.opacity(0.1)
        }
        if time.isEarly {
            return Color.green.opacity(0.1)
        }
        if time.isDelayed {
            return Color.red.opacity(0.1)
        }
        return Color.secondary.opacity(0.05)
    }
    
    // Overlay color based on flight status
    private var overlayColor: Color {
        if time.cancelled {
            return Color.red.opacity(0.3)
        }
        if time.isEarly {
            return Color.green.opacity(0.3)
        }
        if time.isDelayed {
            return Color.red.opacity(0.3)
        }
        return Color.clear
    }
}
