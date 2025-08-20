//
//  FlightRouteMapKitView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/20/25.
//

import SwiftUI
import MapKit

struct FlightRouteMapKitView: UIViewRepresentable {
    let flight: AeroFlight
    @State private var waypoints: [CLLocationCoordinate2D] = []
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        
        // Parse waypoints and setup map
        parseWaypoints()
        setupMapView(mapView)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update map if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func parseWaypoints() {
        guard let route = flight.route else { return }
        
        let components = route.components(separatedBy: " ")
        var parsedWaypoints: [CLLocationCoordinate2D] = []
        
        // Add origin airport
        if let originCoord = AirportCoordinateService.shared.getCoordinate(for: flight.origin.displayCode)?.coordinate {
            parsedWaypoints.append(originCoord)
        }
        
        for component in components {
            // Look for coordinate patterns like "5000N/05000W"
            if let coordinate = parseCoordinate(from: component) {
                parsedWaypoints.append(coordinate)
            }
            // Also check for known airports in the route
            else if let airportCoord = AirportCoordinateService.shared.getCoordinate(for: component)?.coordinate {
                parsedWaypoints.append(airportCoord)
            }
        }
        
        // Add destination airport
        if let destCoord = AirportCoordinateService.shared.getCoordinate(for: flight.destination.displayCode)?.coordinate {
            parsedWaypoints.append(destCoord)
        }
        
        self.waypoints = parsedWaypoints
    }
    
    private func parseCoordinate(from string: String) -> CLLocationCoordinate2D? {
        let parts = string.components(separatedBy: "/")
        guard parts.count == 2 else { return nil }
        
        let latString = parts[0]
        let lonString = parts[1]
        
        // Extract latitude
        guard latString.count >= 3,
              let latDir = latString.last,
              ["N", "S"].contains(String(latDir)) else { return nil }
        
        let latNumberString = String(latString.dropLast())
        guard let latValue = Double(latNumberString) else { return nil }
        
        let latitude: Double
        if latNumberString.count == 4 {
            latitude = latValue / 100.0
        } else if latNumberString.count == 2 {
            latitude = latValue
        } else {
            return nil
        }
        
        // Extract longitude
        guard lonString.count >= 4,
              let lonDir = lonString.last,
              ["E", "W"].contains(String(lonDir)) else { return nil }
        
        let lonNumberString = String(lonString.dropLast())
        guard let lonValue = Double(lonNumberString) else { return nil }
        
        let longitude: Double
        if lonNumberString.count == 5 {
            longitude = lonValue / 100.0
        } else if lonNumberString.count == 3 {
            longitude = lonValue
        } else {
            return nil
        }
        
        let finalLatitude = latitude * (latDir == "N" ? 1 : -1)
        let finalLongitude = longitude * (lonDir == "E" ? 1 : -1)
        
        return CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
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
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        var latDelta = abs(maxLat - minLat) * 1.4
        var lonDelta = abs(maxLon - minLon) * 1.4
        
        // Handle Pacific crossing
        if lonDelta > 180 {
            lonDelta = 360 - lonDelta
        }
        
        // Minimum zoom
        latDelta = max(latDelta, 2.0)
        lonDelta = max(lonDelta, 2.0)
        
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