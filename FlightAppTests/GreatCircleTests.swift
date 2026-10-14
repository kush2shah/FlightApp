//
//  GreatCircleTests.swift
//  FlightAppTests
//

import CoreLocation
import Testing
@testable import FlightApp

struct GreatCircleTests {
    let jfk = CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)
    let lhr = CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)
    let sfo = CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790)
    let nrt = CLLocationCoordinate2D(latitude: 35.7720, longitude: 140.3929)

    @Test func distanceMatchesKnownRoute() {
        // JFK–LHR is ~3,450 statute miles
        let miles = GreatCircle.distanceMiles(from: jfk, to: lhr)
        #expect((3400...3500).contains(miles))
    }

    @Test func arcStartsAndEndsAtAirports() throws {
        let arc = GreatCircle.arc(from: jfk, to: lhr, points: 50)
        #expect(arc.count == 51)

        let first = try #require(arc.first)
        let last = try #require(arc.last)
        #expect(abs(first.latitude - jfk.latitude) < 1e-6 && abs(first.longitude - jfk.longitude) < 1e-6)
        #expect(abs(last.latitude - lhr.latitude) < 1e-6 && abs(last.longitude - lhr.longitude) < 1e-6)
    }

    @Test func arcBowsTowardThePole() {
        // A great circle between two northern-hemisphere airports peaks north of both
        let maxLatitude = GreatCircle.arc(from: jfk, to: lhr).map(\.latitude).max() ?? 0
        #expect(maxLatitude > lhr.latitude)
    }

    @Test func coincidentPointsFallBackToStraightLine() {
        #expect(GreatCircle.arc(from: jfk, to: jfk).count == 2)
    }

    @Test func invalidCoordinatesProduceNoArc() {
        let invalid = CLLocationCoordinate2D(latitude: 120, longitude: 0)
        #expect(GreatCircle.arc(from: invalid, to: lhr).isEmpty)
        #expect(GreatCircle.region(framing: invalid, and: lhr) == nil)
    }

    @Test func regionCentersOnPacificForDateLineCrossing() throws {
        let region = try #require(GreatCircle.region(framing: sfo, and: nrt))
        // Center should be over the Pacific (near -171°), not over Europe/Africa
        #expect((-180 ... -160).contains(region.center.longitude))
        #expect(region.span.longitudeDelta < 180)
    }

    @Test func regionHasMinimumSpanForShortHops() throws {
        let nearby = CLLocationCoordinate2D(latitude: 40.7769, longitude: -73.8740) // LGA
        let region = try #require(GreatCircle.region(framing: jfk, and: nearby))
        #expect(region.span.latitudeDelta >= 5)
        #expect(region.span.longitudeDelta >= 5)
    }
}
