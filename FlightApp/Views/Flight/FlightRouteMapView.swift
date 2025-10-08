//
//  FlightRouteMapView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/20/25.
//

import SwiftUI
import MapKit

struct FlightRouteMapView: View {
    let flight: AeroFlight

    var body: some View {
        VStack(spacing: 0) {
            FlightRouteMapKitView(flight: flight)
                .frame(height: 300)
        }
    }
}
#Preview {
    Text("Preview requires AeroFlight data")
}
