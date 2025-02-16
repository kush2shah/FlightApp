//
//  FlightSelectionCard.swift
//  FlightApp
//
//  Created by Kush Shah on 2/16/25.
//

import SwiftUI

struct FlightSelectionCard: View {
    let flight: AeroFlight
    let onSelect: () -> Void
    
    private var flightIdentifier: String {
        let operator_ = flight.operatorIata ?? flight.operator_ ?? ""
        let number = flight.flightNumber ?? flight.ident
        return "\(operator_) \(number)"
    }
    
    private var statusText: String {
        if flight.cancelled {
            return "Cancelled"
        }
        
        if flight.actualOn != nil {
            if let delay = flight.arrivalDelay {
                if delay > 0 {
                    return "Arrived \(delay.formattedDelay()) late"
                } else if delay < 0 {
                    return "Arrived \(abs(delay).formattedDelay()) early"
                }
            }
            return "Arrived on time"
        }
        
        if flight.isInProgress {
            return "In Flight"
        }
        
        if let scheduledOut = flight.scheduledOut.flatMap({ ISO8601DateFormatter().date(from: $0) }) {
            if scheduledOut > Date() {
                return "Departs \(scheduledOut.formatted(date: .abbreviated, time: .shortened))"
            }
        }
        
        return "Scheduled"
    }
    
    private var statusColor: Color {
        if flight.cancelled { return .red }
        if flight.actualOn != nil {
            if let delay = flight.arrivalDelay {
                if delay > 0 { return .orange }
                if delay < 0 { return .green }
            }
            return .green
        }
        if flight.isInProgress { return .green }
        return .blue
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Flight number and status
                HStack {
                    Text(flightIdentifier)
                        .font(.headline)
                    Spacer()
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }
                
                // Route information
                HStack {
                    VStack(alignment: .leading) {
                        Text(flight.origin.displayCode)
                            .font(.headline)
                        Text(flight.origin.city ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "airplane")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(flight.destination.displayCode)
                            .font(.headline)
                        Text(flight.destination.city ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
