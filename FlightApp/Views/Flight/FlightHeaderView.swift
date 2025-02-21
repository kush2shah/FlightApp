//
//  FlightHeaderView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/21/25.
//

import SwiftUI

struct FlightHeaderView: View {
    let flight: AeroFlight
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        if let operatorName = flight.operatorIata ?? flight.operator_ {
                            Text(operatorName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Text(flight.flightNumber ?? flight.ident)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    if let type = flight.aircraftType {
                        Text(type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}
