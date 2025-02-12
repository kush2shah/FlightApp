//
//  FlightHeader.swift
//  FlightApp
//
//  Created by Kush Shah on 2/11/25.
//

import SwiftUI

struct FlightHeader: View {
    let flight: AeroFlight
    let status: (status: String, color: Color)
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(flight.ident)
                        .font(.title2)
                        .fontWeight(.bold)
                    if let type = flight.aircraftType {
                        Text(type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(status.status)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(status.color.opacity(0.1))
                    .foregroundColor(status.color)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}
