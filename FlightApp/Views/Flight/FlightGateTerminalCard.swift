//
//  FlightGateTerminalCard.swift
//  FlightApp
//
//  Created by Kush Shah on 8/20/25.
//

import SwiftUI

struct FlightGateTerminalCard: View {
    let flight: AeroFlight
    
    private var hasGateInfo: Bool {
        flight.gateOrigin != nil || flight.gateDestination != nil ||
        flight.terminalOrigin != nil || flight.terminalDestination != nil ||
        flight.baggageClaim != nil
    }
    
    var body: some View {
        if hasGateInfo {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.secondary)
                    Text("Gate & Terminal Info")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    // Departure info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Departure")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if let terminal = flight.terminalOrigin {
                            InfoRow(icon: "building", label: "Terminal", value: terminal)
                        }
                        
                        if let gate = flight.gateOrigin {
                            InfoRow(icon: "door.left.hand.open", label: "Gate", value: gate)
                        }
                    }
                    
                    Spacer()
                    
                    // Arrival info
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Arrival")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if let terminal = flight.terminalDestination {
                            InfoRow(icon: "building", label: "Terminal", value: terminal, alignment: .trailing)
                        }
                        
                        if let gate = flight.gateDestination {
                            InfoRow(icon: "door.right.hand.open", label: "Gate", value: gate, alignment: .trailing)
                        }
                    }
                }
                
                // Baggage claim (centered)
                if let baggageClaim = flight.baggageClaim {
                    HStack {
                        Spacer()
                        InfoRow(icon: "suitcase", label: "Baggage Claim", value: baggageClaim)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var alignment: HorizontalAlignment = .leading
    
    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            HStack(spacing: 4) {
                if alignment == .trailing {
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    Text("Preview requires AeroFlight data")
}