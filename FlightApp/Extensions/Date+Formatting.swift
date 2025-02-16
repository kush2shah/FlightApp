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
        // Use system time format preference
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
    
    static func flightDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    static func timezoneFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "z"
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

// Add Date extension for consistent time formatting
extension Date {
    func formattedTime(in timezone: TimeZone = .current) -> String {
        let formatter = DateFormatter.flightTimeFormatter()
        formatter.timeZone = timezone
        return formatter.string(from: self)
    }
    
    func formattedDate(in timezone: TimeZone = .current) -> String {
        let formatter = DateFormatter.flightDateFormatter()
        formatter.timeZone = timezone
        return formatter.string(from: self)
    }
    
    func formattedTimezone(timezone: TimeZone = .current) -> String {
        let formatter = DateFormatter.timezoneFormatter()
        formatter.timeZone = timezone
        return formatter.string(from: self)
    }
}
