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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.secondary)
                Text("Flight Route")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            FlightRouteMapKitView(flight: flight)
                .frame(height: 300)
                .cornerRadius(12)
                .clipped()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
#Preview {
    Text("Preview requires AeroFlight data")
}
