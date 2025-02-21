//
//  RouteInformationView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/21/25.
//

import SwiftUI

struct RouteInformationView: View {
    let flight: AeroFlight
    
    var body: some View {
        HStack {
            AirportView(
                code: flight.origin.displayCode,
                city: flight.origin.city ?? "",
                alignment: .leading
            )
            
            Spacer()
            
            Image(systemName: "airplane")
                .foregroundColor(.secondary)
            
            Spacer()
            
            AirportView(
                code: flight.destination.displayCode,
                city: flight.destination.city ?? "",
                alignment: .trailing
            )
        }
    }
}
