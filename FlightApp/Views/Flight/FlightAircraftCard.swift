//
//  FlightAircraftCard.swift
//  FlightApp
//
//  Created by Kush Shah on 2/20/25.
//

import SwiftUI

struct FlightAircraftCard: View {
    let flight: AeroFlight
    
    private var hasAircraftInfo: Bool {
        flight.aircraftType != nil || flight.registration != nil ||
        flight.filedAltitude != nil || flight.filedAirspeed != nil ||
        flight.route != nil
    }
    
    var body: some View {
        if hasAircraftInfo {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "airplane")
                        .foregroundColor(.secondary)
                    Text("Aircraft & Route")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                // Aircraft details
                if flight.aircraftType != nil || flight.registration != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aircraft")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            if let aircraftType = flight.aircraftType {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Type")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(aircraftType)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            if let registration = flight.registration {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Registration")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(registration)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Flight parameters
                if flight.filedAltitude != nil || flight.filedAirspeed != nil || flight.filedEte != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Flight Parameters")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            if let altitude = flight.filedAltitude {
                                ParameterView(
                                    icon: "arrow.up",
                                    label: "Altitude",
                                    value: "\(altitude) ft"
                                )
                            }
                            
                            if let airspeed = flight.filedAirspeed {
                                ParameterView(
                                    icon: "speedometer",
                                    label: "Speed",
                                    value: "\(airspeed) kts"
                                )
                            }
                            
                            if let duration = flight.filedEte {
                                ParameterView(
                                    icon: "clock",
                                    label: "Duration",
                                    value: formattedDuration(duration)
                                )
                            }
                            
                            Spacer()
                        }
                    }
                }
                
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
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

struct ParameterView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
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