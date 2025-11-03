//
//  FeatureFlags.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import Foundation
import SwiftUI

/// Manages feature flags and API availability settings
class FeatureFlags: ObservableObject {
    static let shared = FeatureFlags()

    @AppStorage("seatsAeroEnabled") var isSeatsAeroEnabled: Bool = true
    @AppStorage("amadeusEnabled") var isAmadeusEnabled: Bool = true
    @AppStorage("amadeusProduction") var isAmadeusProduction: Bool = false
    @AppStorage("trackedFlightsEnabled") var isTrackedFlightsEnabled: Bool = false

    /// Check if Seats.aero API integration is enabled
    var canUseSeatsAero: Bool {
        isSeatsAeroEnabled
    }

    /// Check if Amadeus API integration is enabled
    var canUseAmadeus: Bool {
        isAmadeusEnabled
    }

    /// Check if tracked flights feature is enabled
    var canUseTrackedFlights: Bool {
        isTrackedFlightsEnabled
    }

    private init() {}
}
