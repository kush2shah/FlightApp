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

    /// Check if Seats.aero API integration is enabled
    var canUseSeatsAero: Bool {
        isSeatsAeroEnabled
    }

    private init() {}
}
