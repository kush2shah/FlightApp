//
//  FlightTime.swift
//  FlightApp
//
//  Created by Kush Shah on 2/12/25.
//

import Foundation

struct FlightTime {
    let displayTime: String
    let displayTimezone: String
    let actualTime: String?
    let scheduledTime: String?
    let estimatedTime: String?
    let date: String
    let isEarly: Bool
    let isDelayed: Bool
    let minutesDifference: Int?
    let cancelled: Bool
    
    // Computed property for time status description
    var statusDescription: String? {
        guard !cancelled else { return "Cancelled" }
        
        if let minutesDifference = minutesDifference {
            if isEarly {
                return "\(minutesDifference)m Early"
            } else if isDelayed {
                return "\(minutesDifference)m Delayed"
            }
        }
        
        return nil
    }
    
    init(
        displayTime: String,
        displayTimezone: String,
        actualTime: String? = nil,
        scheduledTime: String? = nil,
        estimatedTime: String? = nil,
        date: String,
        isEarly: Bool = false,
        isDelayed: Bool = false,
        minutesDifference: Int? = nil,
        cancelled: Bool = false
    ) {
        self.displayTime = displayTime
        self.displayTimezone = displayTimezone
        self.actualTime = actualTime
        self.scheduledTime = scheduledTime
        self.estimatedTime = estimatedTime
        self.date = date
        self.isEarly = isEarly
        self.isDelayed = isDelayed
        self.minutesDifference = minutesDifference
        self.cancelled = cancelled
    }
}
