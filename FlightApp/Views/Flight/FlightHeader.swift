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
                    HStack {
                        if let operatorName = flight.operatorIata ?? flight.operator_ {
                            Text(operatorName)
                                .font(.sfRounded(size: 17, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        Text(flight.flightNumber ?? flight.ident)
                            .font(.sfRounded(size: 24, weight: .bold))
                    }
                    
                    if let type = flight.aircraftType {
                        Text(type)
                            .font(.sfRounded(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(status.status)
                    .font(.sfRounded(size: 15, weight: .medium))
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
