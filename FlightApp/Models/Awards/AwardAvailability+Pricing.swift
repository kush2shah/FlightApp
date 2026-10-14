//
//  AwardAvailability+Pricing.swift
//  FlightApp
//
//  Numeric pricing helpers for award availability.
//
//  `getMileageCost(for:)` returns a display string ("35k"), which can't be
//  compared numerically. Sorting and "best award" logic must use these helpers.
//

import Foundation

extension AwardAvailability {
    /// Raw mileage cost string from the API for a cabin (unformatted).
    func rawMileageCost(for cabin: CabinClass) -> String? {
        switch cabin {
        case .first: return fMileageCost
        case .business: return jMileageCost
        case .premiumEconomy: return wMileageCost
        case .economy: return yMileageCost
        }
    }

    /// Numeric mileage cost for a cabin, or nil if unavailable or unparseable.
    func mileageCostValue(for cabin: CabinClass) -> Int? {
        guard let raw = rawMileageCost(for: cabin) else { return nil }
        return Int(raw.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces))
    }

    /// Every available cabin as an `AwardOffer`, for insight prompts.
    var awardOffers: [AwardOffer] {
        let cabins: [(CabinClass, String)] = [
            (.business, "Business"),
            (.first, "First"),
            (.economy, "Economy"),
            (.premiumEconomy, "Premium Economy")
        ]
        return cabins.compactMap { cabin, label in
            guard isCabinAvailable(cabin), let miles = mileageCostValue(for: cabin) else { return nil }
            return AwardOffer(program: source, miles: miles, cabin: label)
        }
    }
}

extension Array where Element == AwardAvailability {
    /// Awards with availability in the cabin, cheapest first, then earliest date.
    func sortedByCost(for cabin: CabinClass) -> [AwardAvailability] {
        filter { $0.isCabinAvailable(cabin) }
            .sorted { lhs, rhs in
                let lhsCost = lhs.mileageCostValue(for: cabin) ?? .max
                let rhsCost = rhs.mileageCostValue(for: cabin) ?? .max
                if lhsCost != rhsCost { return lhsCost < rhsCost }
                return lhs.date < rhs.date
            }
    }

    /// The cheapest award with availability in the cabin.
    func cheapest(for cabin: CabinClass) -> AwardAvailability? {
        sortedByCost(for: cabin).first
    }

    /// Lowest numeric cost for the cabin across all awards.
    func lowestCost(for cabin: CabinClass) -> Int? {
        cheapest(for: cabin)?.mileageCostValue(for: cabin)
    }

    /// Awards available in the cabin, grouped by program and ordered by each program's best price.
    func groupedByProgram(for cabin: CabinClass) -> [(program: String, awards: [AwardAvailability])] {
        Dictionary(grouping: filter { $0.isCabinAvailable(cabin) }, by: \.programName)
            .map { (program: $0.key, awards: $0.value.sorted { $0.date < $1.date }) }
            .sorted { lhs, rhs in
                let lhsCost = lhs.awards.lowestCost(for: cabin) ?? .max
                let rhsCost = rhs.awards.lowestCost(for: cabin) ?? .max
                if lhsCost != rhsCost { return lhsCost < rhsCost }
                return lhs.program < rhs.program
            }
    }
}
