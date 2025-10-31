//
//  FlightRouteMapKitView.swift
//  FlightApp
//
//  Created by Kush Shah on 8/20/25.
//

import SwiftUI
import MapKit

struct FlightRouteMapKitView: UIViewRepresentable {
    let flight: AeroFlight
    @State private var waypoints: [CLLocationCoordinate2D] = []
    @State private var isLoadingRoute = false
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        
        // Start loading waypoints asynchronously
        parseWaypoints()
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update map when waypoints change
        setupMapView(uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func parseWaypoints() {
        // First try to get route data from AeroAPI
        Task {
            await loadRouteFromAPI()
        }
    }
    
    @MainActor
    private func loadRouteFromAPI() async {
        guard !isLoadingRoute else { return }
        isLoadingRoute = true
        
        // Try route string first (more reliable for international routes)
        if let route = flight.route, !route.isEmpty {
            print("🗺️ Using route string: \(route)")
            let parsedWaypoints = WaypointDatabaseService.shared.parseRoute(
                route,
                origin: flight.origin.displayCode,
                destination: flight.destination.displayCode
            )
            
            if !parsedWaypoints.isEmpty {
                self.waypoints = parsedWaypoints
                print("🗺️ Loaded \(parsedWaypoints.count) waypoints from route string")
                for (index, waypoint) in parsedWaypoints.enumerated() {
                    print("  \(index): \(waypoint.latitude), \(waypoint.longitude)")
                }
                isLoadingRoute = false
                return
            }
        }
        
        // Fallback to AeroAPI if route string parsing didn't work
        do {
            let routeResponse = try await AeroAPIService.shared.getFlightRoute(flight.faFlightId)
            
            if !routeResponse.fixes.isEmpty {
                let apiWaypoints = WaypointDatabaseService.shared.parseRouteFromAeroAPI(routeResponse.fixes)
                self.waypoints = apiWaypoints
                print("🗺️ Fallback: Loaded \(apiWaypoints.count) waypoints from AeroAPI")
            }
        } catch {
            print("⚠️ Failed to load route from both sources: \(error)")
        }
        
        isLoadingRoute = false
    }
    
    private func fallbackToRouteString() {
        guard let route = flight.route else {
            print("⚠️ No route string available")
            return
        }
        
        // Use the fallback waypoint database service to parse the route string
        let parsedWaypoints = WaypointDatabaseService.shared.parseRoute(
            route,
            origin: flight.origin.displayCode,
            destination: flight.destination.displayCode
        )
        
        self.waypoints = parsedWaypoints
        
        print("🗺️ Fallback: Parsed \(parsedWaypoints.count) waypoints from route: \(route)")
    }
    
    
    private func setupMapView(_ mapView: MKMapView) {
        // Clear existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add airport annotations
        let originCoord = AirportCoordinateService.shared.getCoordinate(for: flight.origin.displayCode)?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let destCoord = AirportCoordinateService.shared.getCoordinate(for: flight.destination.displayCode)?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        
        let originAnnotation = AirportAnnotation(coordinate: originCoord, title: flight.origin.displayCode, isOrigin: true)
        let destAnnotation = AirportAnnotation(coordinate: destCoord, title: flight.destination.displayCode, isOrigin: false)
        
        mapView.addAnnotations([originAnnotation, destAnnotation])
        
        // Add route polyline if we have waypoints
        if waypoints.count >= 2 {
            let polyline = MKPolyline(coordinates: waypoints, count: waypoints.count)
            mapView.addOverlay(polyline)
        }
        
        // Set region to show the entire route
        if !waypoints.isEmpty {
            let region = regionForCoordinates(waypoints)
            mapView.setRegion(region, animated: false)
        } else {
            // Fallback to origin-destination region
            let region = regionForCoordinates([originCoord, destCoord])
            mapView.setRegion(region, animated: false)
        }
    }
    
    private func regionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
        }
        
        // Filter out any invalid coordinates
        let validCoordinates = coordinates.filter { coord in
            coord.latitude >= -90 && coord.latitude <= 90 &&
            coord.longitude >= -180 && coord.longitude <= 180 &&
            !coord.latitude.isNaN && !coord.longitude.isNaN &&
            !coord.latitude.isInfinite && !coord.longitude.isInfinite
        }
        
        guard !validCoordinates.isEmpty else {
            print("⚠️ No valid coordinates for map region")
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
        }
        
        let latitudes = validCoordinates.map { $0.latitude }
        let longitudes = validCoordinates.map { $0.longitude }
        
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!
        
        let centerLat = (minLat + maxLat) / 2
        var centerLon = (minLon + maxLon) / 2
        
        var latDelta = abs(maxLat - minLat) * 1.4
        var lonDelta = abs(maxLon - minLon) * 1.4
        
        // Handle date line crossing (Pacific/International date line)
        if lonDelta > 180 {
            // Recalculate center for date line crossing
            let adjustedLons = longitudes.map { $0 < 0 ? $0 + 360 : $0 }
            let adjustedMinLon = adjustedLons.min()!
            let adjustedMaxLon = adjustedLons.max()!
            var adjustedCenterLon = (adjustedMinLon + adjustedMaxLon) / 2
            if adjustedCenterLon > 180 {
                adjustedCenterLon -= 360
            }
            centerLon = adjustedCenterLon
            
            // Recalculate delta for crossing
            lonDelta = (adjustedMaxLon - adjustedMinLon) * 1.4
            lonDelta = min(lonDelta, 340) // Cap at reasonable maximum
        }
        
        // Cap deltas to prevent invalid regions (especially for transoceanic flights)
        latDelta = min(max(latDelta, 2.0), 160) // Min 2°, Max 160° (leave poles visible)
        lonDelta = min(max(lonDelta, 2.0), 340) // Min 2°, Max 340° (almost full wrap)
        
        // Final validation
        guard centerLat >= -90 && centerLat <= 90 &&
              centerLon >= -180 && centerLon <= 180 &&
              latDelta > 0 && latDelta <= 180 &&
              lonDelta > 0 && lonDelta <= 360 else {
            print("⚠️ Calculated region is invalid, using fallback")
            return MKCoordinateRegion(
                center: validCoordinates.first!,
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
        }
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: FlightRouteMapKitView
        
        init(_ parent: FlightRouteMapKitView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 3.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let airportAnnotation = annotation as? AirportAnnotation else { return nil }
            
            let identifier = "AirportAnnotation"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView.annotation = annotation
            annotationView.markerTintColor = airportAnnotation.isOrigin ? .systemGreen : .systemBlue
            annotationView.glyphImage = UIImage(systemName: airportAnnotation.isOrigin ? "airplane.departure" : "airplane.arrival")
            annotationView.canShowCallout = true
            
            return annotationView
        }
    }
}

class AirportAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let isOrigin: Bool
    
    init(coordinate: CLLocationCoordinate2D, title: String, isOrigin: Bool) {
        self.coordinate = coordinate
        self.title = title
        self.isOrigin = isOrigin
    }
}
