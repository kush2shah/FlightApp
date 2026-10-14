//
//  RouteMapSection.swift
//  FlightApp
//
//  Hero map for RouteView: great-circle arc with a glass stats overlay.
//

import SwiftUI
import MapKit

struct RouteMapSection: View {
    let origin: AeroAirport?
    let destination: AeroAirport?
    let route: IFRRouteInfo?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let origin, let destination,
               let originCoord = AirportCoordinateService.shared.getCoordinate(for: origin.displayCode),
               let destCoord = AirportCoordinateService.shared.getCoordinate(for: destination.displayCode) {
                SimpleRouteMapView(origin: originCoord.coordinate, destination: destCoord.coordinate)
                statsOverlay(origin: origin, destination: destination)
            } else {
                Color(.systemGray6)
                VStack {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Map unavailable")
                        .font(.sfRounded(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func statsOverlay(origin: AeroAirport, destination: AeroAirport) -> some View {
        HStack(spacing: 24) {
            // Only show distance if we have route data
            if let route {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.sfRounded(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(route.routeDistance)
                        .font(.sfRounded(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }

                Divider()
                    .frame(height: 30)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Route")
                    .font(.sfRounded(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Text(origin.displayCode)
                        .font(.sfRounded(size: 18, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                    Text(destination.displayCode)
                        .font(.sfRounded(size: 18, weight: .bold))
                }
                .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

/// MKMapView showing a great-circle arc between two airports
struct SimpleRouteMapView: UIViewRepresentable {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)

        guard GreatCircle.isValid(origin), GreatCircle.isValid(destination) else { return }

        let arc = GreatCircle.arc(from: origin, to: destination)
        if !arc.isEmpty {
            mapView.addOverlay(MKPolyline(coordinates: arc, count: arc.count))
        }

        let region = GreatCircle.region(framing: origin, and: destination)
            ?? MKCoordinateRegion(center: origin, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
        mapView.setRegion(region, animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 3
            return renderer
        }
    }
}
