//
//  TrackedFlightsMapView.swift
//  FlightApp
//
//  Map view showing great circle paths for all tracked flights
//

import SwiftUI
import MapKit

struct TrackedFlightsMapView: View {
    let trackedFlights: [TrackedFlight]
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            ForEach(annotations) { annotation in
                Marker(annotation.code, coordinate: annotation.coordinate)
                    .tint(annotation.isOrigin ? .green : .red)
            }

            // Draw great circle paths using MapPolyline
            ForEach(greatCirclePaths, id: \.self) { path in
                MapPolyline(coordinates: calculateGreatCirclePoints(from: path.origin, to: path.destination, numberOfPoints: 100))
                    .stroke(.blue.opacity(0.6), lineWidth: 2)
            }
        }
        .onAppear {
            updateMapPosition()
        }
        .onChange(of: trackedFlights) {
            updateMapPosition()
        }
    }

    // MARK: - Computed Properties

    private var annotations: [TrackedFlightAnnotation] {
        var items: [TrackedFlightAnnotation] = []

        for flight in trackedFlights {
            if let originLat = flight.originLat, let originLon = flight.originLon {
                items.append(TrackedFlightAnnotation(
                    id: "\(flight.id)-origin",
                    coordinate: CLLocationCoordinate2D(latitude: originLat, longitude: originLon),
                    code: flight.originCode,
                    isOrigin: true
                ))
            }

            if let destLat = flight.destinationLat, let destLon = flight.destinationLon {
                items.append(TrackedFlightAnnotation(
                    id: "\(flight.id)-dest",
                    coordinate: CLLocationCoordinate2D(latitude: destLat, longitude: destLon),
                    code: flight.destinationCode,
                    isOrigin: false
                ))
            }
        }

        return items
    }

    private var greatCirclePaths: [FlightPath] {
        trackedFlights.compactMap { flight in
            guard let originLat = flight.originLat,
                  let originLon = flight.originLon,
                  let destLat = flight.destinationLat,
                  let destLon = flight.destinationLon else {
                return nil
            }

            return FlightPath(
                origin: CLLocationCoordinate2D(latitude: originLat, longitude: originLon),
                destination: CLLocationCoordinate2D(latitude: destLat, longitude: destLon)
            )
        }
    }

    // MARK: - Helper Methods

    private func updateMapPosition() {
        guard !trackedFlights.isEmpty else {
            position = .automatic
            return
        }

        var minLat: Double = 90
        var maxLat: Double = -90
        var minLon: Double = 180
        var maxLon: Double = -180

        for flight in trackedFlights {
            if let lat = flight.originLat, let lon = flight.originLon {
                minLat = min(minLat, lat)
                maxLat = max(maxLat, lat)
                minLon = min(minLon, lon)
                maxLon = max(maxLon, lon)
            }

            if let lat = flight.destinationLat, let lon = flight.destinationLon {
                minLat = min(minLat, lat)
                maxLat = max(maxLat, lat)
                minLon = min(minLon, lon)
                maxLon = max(maxLon, lon)
            }
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 10),
            longitudeDelta: max((maxLon - minLon) * 1.5, 10)
        )

        let region = MKCoordinateRegion(center: center, span: span)
        position = .region(region)
    }

    private func calculateGreatCirclePoints(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        numberOfPoints: Int
    ) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []

        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180

        let d = 2 * asin(sqrt(
            pow(sin((lat1 - lat2) / 2), 2) +
            cos(lat1) * cos(lat2) * pow(sin((lon1 - lon2) / 2), 2)
        ))

        for i in 0...numberOfPoints {
            let f = Double(i) / Double(numberOfPoints)

            let a = sin((1 - f) * d) / sin(d)
            let b = sin(f * d) / sin(d)

            let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
            let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
            let z = a * sin(lat1) + b * sin(lat2)

            let lat = atan2(z, sqrt(x * x + y * y)) * 180 / .pi
            let lon = atan2(y, x) * 180 / .pi

            points.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }

        return points
    }
}

// MARK: - Supporting Types

struct TrackedFlightAnnotation: Identifiable, Hashable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let code: String
    let isOrigin: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TrackedFlightAnnotation, rhs: TrackedFlightAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

struct FlightPath: Hashable {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D

    func hash(into hasher: inout Hasher) {
        hasher.combine(origin.latitude)
        hasher.combine(origin.longitude)
        hasher.combine(destination.latitude)
        hasher.combine(destination.longitude)
    }

    static func == (lhs: FlightPath, rhs: FlightPath) -> Bool {
        lhs.origin.latitude == rhs.origin.latitude &&
        lhs.origin.longitude == rhs.origin.longitude &&
        lhs.destination.latitude == rhs.destination.latitude &&
        lhs.destination.longitude == rhs.destination.longitude
    }
}


#Preview {
    TrackedFlightsMapView(trackedFlights: [
        TrackedFlight(
            flightNumber: "AA100",
            originCode: "JFK",
            destinationCode: "LAX",
            originLat: 40.6413,
            originLon: -73.7781,
            destinationLat: 33.9416,
            destinationLon: -118.4085
        ),
        TrackedFlight(
            flightNumber: "BA112",
            originCode: "LHR",
            destinationCode: "JFK",
            originLat: 51.4700,
            originLon: -0.4543,
            destinationLat: 40.6413,
            destinationLon: -73.7781
        )
    ])
}
