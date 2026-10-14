//
//  GreatCircle.swift
//  FlightApp
//
//  Great-circle geometry for drawing routes between airports.
//

import CoreLocation
import MapKit

enum GreatCircle {
    static let metersPerMile = 1609.34

    static func isValid(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude.isFinite && coordinate.longitude.isFinite &&
            (-90...90).contains(coordinate.latitude) &&
            (-180...180).contains(coordinate.longitude)
    }

    /// Great-circle distance in miles.
    static func distanceMiles(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation) / metersPerMile
    }

    /// Points along the great-circle arc between two coordinates, endpoints included.
    /// Falls back to a straight segment for coincident or antipodal points.
    static func arc(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, points: Int = 100) -> [CLLocationCoordinate2D] {
        guard isValid(start), isValid(end) else { return [] }

        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180

        // Haversine angular distance
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let d = 2 * atan2(sqrt(a), sqrt(1 - a))
        let sinD = sin(d)

        guard d.isFinite, d >= 0.0001, abs(sinD) >= 0.0001, points > 0 else {
            return [start, end]
        }

        let coordinates = (0...points).compactMap { i -> CLLocationCoordinate2D? in
            let fraction = Double(i) / Double(points)
            let a = sin((1 - fraction) * d) / sinD
            let b = sin(fraction * d) / sinD

            let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
            let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
            let z = a * sin(lat1) + b * sin(lat2)

            let point = CLLocationCoordinate2D(
                latitude: atan2(z, sqrt(x * x + y * y)) * 180 / .pi,
                longitude: atan2(y, x) * 180 / .pi
            )
            return isValid(point) ? point : nil
        }

        return coordinates.count >= 2 ? coordinates : [start, end]
    }

    /// A padded map region framing both endpoints, handling date-line crossings.
    static func region(framing origin: CLLocationCoordinate2D, and dest: CLLocationCoordinate2D) -> MKCoordinateRegion? {
        guard isValid(origin), isValid(dest) else { return nil }

        let centerLat = (origin.latitude + dest.latitude) / 2
        var centerLon = (origin.longitude + dest.longitude) / 2

        let lonDiff = abs(origin.longitude - dest.longitude)
        if lonDiff > 180 {
            // Crosses the date line: average in 0...360 space, then wrap back
            let originLon = origin.longitude < 0 ? origin.longitude + 360 : origin.longitude
            let destLon = dest.longitude < 0 ? dest.longitude + 360 : dest.longitude
            centerLon = (originLon + destLon) / 2
            if centerLon > 180 { centerLon -= 360 }
        }

        let latDelta = abs(origin.latitude - dest.latitude)
        let lonDelta = min(lonDiff, 360 - lonDiff)

        // Pad, cap so transoceanic routes don't show the whole globe, and keep a minimum for short hops
        let paddingMultiplier = 1.4
        let finalLatDelta = max(min(latDelta * paddingMultiplier + 10, 160), 5)
        let finalLonDelta = max(min(lonDelta * paddingMultiplier + 20, 340), 5)

        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        guard isValid(center) else { return nil }

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLonDelta)
        )
    }
}
