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
    
    func smartRelativeDate(in timezone: TimeZone = .current) -> String {
        let calendar = Calendar.current
        var calendarWithTimezone = calendar
        calendarWithTimezone.timeZone = timezone
        
        let now = Date()
        let selfInTimezone = self
        
        if calendarWithTimezone.isDateInToday(selfInTimezone) {
            return "Today"
        } else if calendarWithTimezone.isDateInTomorrow(selfInTimezone) {
            return "Tomorrow"
        } else if calendarWithTimezone.isDateInYesterday(selfInTimezone) {
            return "Yesterday"
        } else {
            let daysDiff = calendarWithTimezone.dateComponents([.day], from: now, to: selfInTimezone).day ?? 0
            
            if abs(daysDiff) <= 6 {
                let formatter = DateFormatter()
                formatter.timeZone = timezone
                formatter.dateFormat = "EEEE"
                return formatter.string(from: selfInTimezone)
            } else {
                let formatter = DateFormatter()
                formatter.timeZone = timezone
                formatter.dateFormat = "EEE, MMM d"
                
                if !calendarWithTimezone.isDate(selfInTimezone, equalTo: now, toGranularity: .year) {
                    formatter.dateFormat = "EEE, MMM d, yyyy"
                }
                
                return formatter.string(from: selfInTimezone)
            }
        }
    }
    
    func flightDateWithContext(in timezone: TimeZone = .current) -> String {
        let relativeDate = smartRelativeDate(in: timezone)
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "MMM d"
        
        let calendar = Calendar.current
        var calendarWithTimezone = calendar
        calendarWithTimezone.timeZone = timezone
        
        if !calendarWithTimezone.isDate(self, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        let standardDate = formatter.string(from: self)
        
        // Only show relative date for Today/Tomorrow/Yesterday
        // For other dates, show the formatted date without duplication
        if relativeDate == "Today" || relativeDate == "Tomorrow" || relativeDate == "Yesterday" {
            return relativeDate
        } else if relativeDate.contains(",") {
            // Already contains full context (e.g., "Wed, Jan 15")
            return relativeDate
        } else {
            // Day of week, add the date
            return "\(relativeDate), \(standardDate)"
        }
    }
}
