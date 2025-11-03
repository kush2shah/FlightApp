//
//  AwardFilters.swift
//  FlightApp
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

/// Cabin class options for award search
enum CabinClass: String, CaseIterable, Codable {
    case economy = "economy"
    case premiumEconomy = "premium"
    case business = "business"
    case first = "first"

    var displayName: String {
        switch self {
        case .economy: return "Economy"
        case .premiumEconomy: return "Premium Economy"
        case .business: return "Business"
        case .first: return "First"
        }
    }

    var shortName: String {
        switch self {
        case .economy: return "Y"
        case .premiumEconomy: return "W"
        case .business: return "J"
        case .first: return "F"
        }
    }

    var icon: String {
        switch self {
        case .economy: return "airplane.circle"
        case .premiumEconomy: return "airplane.circle.fill"
        case .business: return "sparkles"
        case .first: return "crown.fill"
        }
    }

    /// Numeric priority for smart sorting (higher = better cabin)
    var priority: Int {
        switch self {
        case .economy: return 1
        case .premiumEconomy: return 2
        case .business: return 3
        case .first: return 4
        }
    }
}

/// Date range options for award search
struct DateRange: Codable, Equatable {
    var startDate: Date
    var endDate: Date

    static var next30Days: DateRange {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 30, to: start) ?? start
        return DateRange(startDate: start, endDate: end)
    }

    static var next7Days: DateRange {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        return DateRange(startDate: start, endDate: end)
    }

    static var next60Days: DateRange {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 60, to: start) ?? start
        return DateRange(startDate: start, endDate: end)
    }

    static var next90Days: DateRange {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 90, to: start) ?? start
        return DateRange(startDate: start, endDate: end)
    }

    var daysCount: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

/// User preferences for award search filtering
struct AwardFilters {
    var selectedCabins: Set<CabinClass>
    var dateRange: DateRange
    var selectedPrograms: Set<String>
    var maxPoints: Int?

    init(
        selectedCabins: Set<CabinClass> = Set(CabinClass.allCases),
        dateRange: DateRange = .next30Days,
        selectedPrograms: Set<String> = [],
        maxPoints: Int? = nil
    ) {
        self.selectedCabins = selectedCabins
        self.dateRange = dateRange
        self.selectedPrograms = selectedPrograms
        self.maxPoints = maxPoints
    }

    /// Returns comma-separated string of cabin codes for API
    var cabinsParameter: String {
        selectedCabins
            .sorted { $0.priority < $1.priority }
            .map { $0.rawValue }
            .joined(separator: ",")
    }

    /// Check if any filters are active (non-default)
    var hasActiveFilters: Bool {
        // Not default if:
        // - Not all cabins selected
        // - Date range is not 30 days
        // - Specific programs selected
        // - Max points set
        return selectedCabins.count != CabinClass.allCases.count ||
               dateRange != .next30Days ||
               !selectedPrograms.isEmpty ||
               maxPoints != nil
    }

    /// Reset all filters to defaults
    mutating func reset() {
        selectedCabins = Set(CabinClass.allCases)
        dateRange = .next30Days
        selectedPrograms = []
        maxPoints = nil
    }
}

/// Persistent storage for default award search preferences
class AwardPreferences: ObservableObject {
    static let shared = AwardPreferences()

    @AppStorage("defaultSearchCabins") private var defaultCabinsRaw: String = "economy,premium,business,first"
    @AppStorage("showAllCabinsInResults") var showAllCabinsInResults: Bool = true
    @AppStorage("defaultDateRangeDays") var defaultDateRangeDays: Int = 30

    var defaultCabins: Set<CabinClass> {
        get {
            let cabinStrings = defaultCabinsRaw.split(separator: ",").map(String.init)
            return Set(cabinStrings.compactMap { CabinClass(rawValue: $0) })
        }
        set {
            defaultCabinsRaw = newValue
                .sorted { $0.priority < $1.priority }
                .map { $0.rawValue }
                .joined(separator: ",")
        }
    }

    var defaultDateRange: DateRange {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: defaultDateRangeDays, to: start) ?? start
        return DateRange(startDate: start, endDate: end)
    }

    /// Create filter instance with user's default preferences
    func createDefaultFilters() -> AwardFilters {
        AwardFilters(
            selectedCabins: defaultCabins,
            dateRange: defaultDateRange
        )
    }
}
