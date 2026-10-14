//
//  String+ISO8601Duration.swift
//  FlightApp
//
//  Parsing for the ISO 8601 durations Amadeus returns ("PT7H30M").
//

import Foundation

extension String {
    /// Duration in hours for an ISO 8601 time duration ("PT7H30M" -> 7.5).
    /// Returns nil when the string isn't a "PT…" duration.
    var iso8601DurationHours: Double? {
        guard hasPrefix("PT") else { return nil }
        var hours = 0.0
        var number = ""
        var sawComponent = false

        for character in dropFirst(2) {
            if character.isNumber || character == "." {
                number.append(character)
                continue
            }
            guard let value = Double(number) else { return nil }
            switch character {
            case "H": hours += value
            case "M": hours += value / 60
            case "S": hours += value / 3600
            default: return nil
            }
            number = ""
            sawComponent = true
        }

        return sawComponent && number.isEmpty ? hours : nil
    }

    /// Short display form of an ISO 8601 duration ("PT7H30M" -> "7h 30m").
    var formattedISO8601Duration: String {
        guard let hours = iso8601DurationHours else { return self }
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        switch (h, m) {
        case (0, _): return "\(m)m"
        case (_, 0): return "\(h)h"
        default: return "\(h)h \(m)m"
        }
    }
}
