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
    @State private var region = MKCoordinateRegion()
    @State private var waypoints: [CLLocationCoordinate2D] = []
    
    private var hasValidRoute: Bool {
        waypoints.count >= 2
    }
    
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
            
            if hasValidRoute {
                Map(coordinateRegion: $region, annotationItems: routeAnnotations()) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        annotation.view
                    }
                }
                .overlay(
                    RouteOverlay(waypoints: waypoints)
                )
                .frame(height: 200)
                .cornerRadius(12)
                .clipped()
            } else {
                // Fallback to simple origin-destination map
                Map(coordinateRegion: $region, annotationItems: basicAnnotations()) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        annotation.view
                    }
                }
                .frame(height: 200)
                .cornerRadius(12)
                .clipped()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            setupMapRegion()
            parseWaypoints()
        }
    }
    
    private func setupMapRegion() {
        // Get actual airport coordinates
        let originCoord = AirportCoordinateService.shared.getCoordinate(for: flight.origin.displayCode)?.coordinate ?? CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let destCoord = AirportCoordinateService.shared.getCoordinate(for: flight.destination.displayCode)?.coordinate ?? CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)
        
        let centerLat = (originCoord.latitude + destCoord.latitude) / 2
        let centerLon = (originCoord.longitude + destCoord.longitude) / 2
        
        let latDelta = abs(destCoord.latitude - originCoord.latitude) * 1.3
        let lonDelta = abs(destCoord.longitude - originCoord.longitude) * 1.3
        
        // Ensure minimum zoom level
        let minDelta = 5.0
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, minDelta),
                longitudeDelta: max(lonDelta, minDelta)
            )
        )
    }
    
    private func parseWaypoints() {
        guard let route = flight.route else { return }
        
        // Parse waypoints from route string
        // This is a simplified parser - real implementation would need waypoint database
        let components = route.components(separatedBy: " ")
        var parsedWaypoints: [CLLocationCoordinate2D] = []
        
        for component in components {
            // Look for coordinate patterns like "5000N/05000W"
            if let coordinate = parseCoordinate(from: component) {
                parsedWaypoints.append(coordinate)
            }
        }
        
        self.waypoints = parsedWaypoints
    }
    
    private func parseCoordinate(from string: String) -> CLLocationCoordinate2D? {
        // Parse coordinate strings like "5000N/05000W"
        let parts = string.components(separatedBy: "/")
        guard parts.count == 2 else { return nil }
        
        let latString = parts[0]
        let lonString = parts[1]
        
        // Extract latitude
        guard latString.count >= 5,
              let latValue = Double(String(latString.prefix(4))),
              let latDir = latString.last else { return nil }
        
        // Extract longitude
        guard lonString.count >= 6,
              let lonValue = Double(String(lonString.prefix(5))),
              let lonDir = lonString.last else { return nil }
        
        let latitude = latValue / 100.0 * (latDir == "N" ? 1 : -1)
        let longitude = lonValue / 100.0 * (lonDir == "E" ? 1 : -1)
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private func routeAnnotations() -> [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        if let first = waypoints.first {
            annotations.append(MapAnnotationItem(
                id: "origin",
                coordinate: first,
                view: AnyView(
                    Image(systemName: "airplane.departure")
                        .foregroundColor(.green)
                        .background(Circle().fill(.white))
                )
            ))
        }
        
        if let last = waypoints.last {
            annotations.append(MapAnnotationItem(
                id: "destination",
                coordinate: last,
                view: AnyView(
                    Image(systemName: "airplane.arrival")
                        .foregroundColor(.blue)
                        .background(Circle().fill(.white))
                )
            ))
        }
        
        return annotations
    }
    
    private func basicAnnotations() -> [MapAnnotationItem] {
        // Use actual airport coordinates when available
        let originCoord = AirportCoordinateService.shared.getCoordinate(for: flight.origin.displayCode)?.coordinate ?? CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let destCoord = AirportCoordinateService.shared.getCoordinate(for: flight.destination.displayCode)?.coordinate ?? CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)
        
        return [
            MapAnnotationItem(
                id: "origin",
                coordinate: originCoord,
                view: AnyView(
                    VStack(spacing: 2) {
                        Image(systemName: "airplane.departure")
                            .foregroundColor(.green)
                            .background(Circle().fill(.white).frame(width: 20, height: 20))
                        Text(flight.origin.displayCode)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                )
            ),
            MapAnnotationItem(
                id: "destination", 
                coordinate: destCoord,
                view: AnyView(
                    VStack(spacing: 2) {
                        Image(systemName: "airplane.arrival")
                            .foregroundColor(.blue)
                            .background(Circle().fill(.white).frame(width: 20, height: 20))
                        Text(flight.destination.displayCode)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                )
            )
        ]
    }
}

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let view: AnyView
}

struct RouteOverlay: View {
    let waypoints: [CLLocationCoordinate2D]
    
    var body: some View {
        // This would draw a line connecting waypoints
        // Implementation would use MapKit's overlay system
        EmptyView()
    }
}

#Preview {
    Text("Preview requires AeroFlight data")
}