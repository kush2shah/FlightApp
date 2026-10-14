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

    @AppStorage var isSeatsAeroEnabled: Bool
    @AppStorage var isAmadeusEnabled: Bool
    @AppStorage var isAmadeusProduction: Bool
    @AppStorage var isTrackedFlightsEnabled: Bool

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

    /// - Parameter defaults: Backing store; tests pass an isolated suite.
    init(defaults: UserDefaults = .standard) {
        _isSeatsAeroEnabled = AppStorage(wrappedValue: true, "seatsAeroEnabled", store: defaults)
        _isAmadeusEnabled = AppStorage(wrappedValue: true, "amadeusEnabled", store: defaults)
        _isAmadeusProduction = AppStorage(wrappedValue: false, "amadeusProduction", store: defaults)
        _isTrackedFlightsEnabled = AppStorage(wrappedValue: false, "trackedFlightsEnabled", store: defaults)
    }
}
