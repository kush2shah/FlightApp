//
//  ActiveFlightCard.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct ActiveFlightCard: View {
    var body: some View {
        VStack(spacing: 20) {
            // Airline and flight info
            HStack {
                Image(systemName: "airplane")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("United Airlines")
                        .font(.system(size: 18, weight: .semibold))
                    Text("UA 837")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            // Route visualization
            HStack(alignment: .center) {
                // Origin
                VStack(alignment: .leading) {
                    Text("SFO")
                        .font(.system(size: 24, weight: .bold))
                    Text("11:20 AM")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Flight path
                ZStack {
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.blue.opacity(0.3))
                        .frame(height: 2)
                    
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(45))
                }
                
                // Destination
                VStack(alignment: .trailing) {
                    Text("NRT")
                        .font(.system(size: 24, weight: .bold))
                    Text("4:45 PM")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Flight stats
            HStack(spacing: 20) {
                FlightStat(icon: "speedometer", value: "561", unit: "mph")
                FlightStat(icon: "arrow.up.forward", value: "38k", unit: "ft")
                FlightStat(icon: "thermometer", value: "-58°", unit: "F")
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10, x: 0, y: 5)
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

struct FlightStat: View {
    let icon: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
            Text(unit)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ActiveFlightCard()
}
