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

    private var airlineCode: String? {
        flight.operatorIata ?? flight.operatorIcao
    }

    private var brandColors: AirlineBrandColors? {
        AirlineColorService.shared.getBrandColors(for: airlineCode)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            FlightRouteMapKitView(flight: flight)
                .frame(height: 350)

            // Stats overlay with branded glass effect
            HStack(spacing: 20) {
                if let distance = flight.routeDistance {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Distance")
                            .font(.sfRounded(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(distance) mi")
                            .font(.sfRounded(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }

                if distance != nil && flight.filedEte != nil {
                    Divider()
                        .frame(height: 30)
                }

                if let duration = flight.filedEte {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.sfRounded(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(formattedDuration(duration))
                            .font(.sfRounded(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .brandedGlassEffect(colors: brandColors, cornerRadius: 16, intensity: 0.22)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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

    private var distance: Int? {
        flight.routeDistance
    }
}
#Preview {
    Text("Preview requires AeroFlight data")
}
