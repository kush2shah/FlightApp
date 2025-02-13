//
//  Date+Formatting.swift
//  FlightApp
//
//  Created by Kush Shah on 2/13/25.
//

import Foundation

extension DateFormatter {
    static func flightTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    static func flightDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
}

extension ISO8601DateFormatter {
    static func standardFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
