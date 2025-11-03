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
            HStack(spacing: 24) {
                // Departure
                if flight.gateOrigin != nil || flight.terminalOrigin != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Departure")
                            .font(.sfRounded(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        if let gate = flight.gateOrigin {
                            HStack(spacing: 6) {
                                Image(systemName: "door.left.hand.open")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                Text("Gate \(gate)")
                                    .font(.sfRounded(size: 18, weight: .bold))
                            }
                        }

                        if let terminal = flight.terminalOrigin {
                            Text("Terminal \(terminal)")
                                .font(.sfRounded(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if (flight.gateOrigin != nil || flight.terminalOrigin != nil) &&
                   (flight.gateDestination != nil || flight.terminalDestination != nil) {
                    Divider()
                        .frame(height: 40)
                }

                // Arrival
                if flight.gateDestination != nil || flight.terminalDestination != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Arrival")
                            .font(.sfRounded(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        if let gate = flight.gateDestination {
                            HStack(spacing: 6) {
                                Image(systemName: "door.right.hand.open")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                Text("Gate \(gate)")
                                    .font(.sfRounded(size: 18, weight: .bold))
                            }
                        }

                        if let terminal = flight.terminalDestination {
                            Text("Terminal \(terminal)")
                                .font(.sfRounded(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Baggage claim (if available)
                if let baggageClaim = flight.baggageClaim {
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Baggage")
                            .font(.sfRounded(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 6) {
                            Image(systemName: "suitcase")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text(baggageClaim)
                                .font(.sfRounded(size: 18, weight: .bold))
                        }
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        }
    }
}

#Preview {
    Text("Preview requires AeroFlight data")
}