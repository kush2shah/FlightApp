//
//  FlightViewModel.swift
//  FlightApp
//
//  Created by Kush Shah on 2/9/25.
//

import SwiftUI

@MainActor
class FlightViewModel: ObservableObject {
    @Published var currentFlight: AeroFlight?
    @Published var isLoading = false
    @Published var error: Error?
    
    func searchFlight(flightNumber: String) {
        guard !flightNumber.isEmpty else {
            self.error = AeroAPIError.invalidURL
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                print("🔎 Searching for flight: \(flightNumber)")
                let flight = try await AeroAPIService.shared.getFlightInfo(flightNumber)
                
                print("✅ Found flight: \(flight.ident)")
                self.currentFlight = flight
            } catch {
                print("❌ Error: \(error)")
                self.error = error
            }
            
            isLoading = false
        }
    }
    
    func getFlightTimes() -> (departure: FlightTime, arrival: FlightTime) {
        guard let flight = currentFlight else {
            return (
                FlightTime(
                    displayTime: "--:--",
                    displayTimezone: "UTC",
                    actualTime: nil,
                    scheduledTime: nil,
                    estimatedTime: nil,
                    date: "---",
                    isEarly: false,
                    isDelayed: false,
                    minutesDifference: nil,
                    cancelled: false
                ),
                FlightTime(
                    displayTime: "--:--",
                    displayTimezone: "UTC",
                    actualTime: nil,
                    scheduledTime: nil,
                    estimatedTime: nil,
                    date: "---",
                    isEarly: false,
                    isDelayed: false,
                    minutesDifference: nil,
                    cancelled: false
                )
            )
        }
        
        let departure = formatTimeWithZone(
            actual: flight.actualOut,
            estimated: flight.estimatedOut,
            scheduled: flight.scheduledOut,
            timezone: flight.origin.timezone ?? "UTC",
            isCancelled: flight.cancelled
        )
        
        let arrival = formatTimeWithZone(
            actual: flight.actualOn,
            estimated: flight.estimatedOn,
            scheduled: flight.scheduledOn,
            timezone: flight.destination.timezone ?? "UTC",
            isCancelled: flight.cancelled
        )
        
        return (departure, arrival)
    }
    
    private func formatTimeWithZone(actual: String?, estimated: String?, scheduled: String?, timezone: String, isCancelled: Bool = false) -> FlightTime {
        let apiFormatter = ISO8601DateFormatter()
        apiFormatter.formatOptions = [.withInternetDateTime]
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let timezoneFormatter = DateFormatter()
        timezoneFormatter.dateFormat = "z"
        
        var displayTimezone = "UTC"
        if let timeZone = TimeZone(identifier: timezone) {
            timeFormatter.timeZone = timeZone
            dateFormatter.timeZone = timeZone
            timezoneFormatter.timeZone = timeZone
            displayTimezone = timezoneFormatter.string(from: Date())
        }
        
        // Get all date versions
        let actualDate = actual.flatMap { apiFormatter.date(from: $0) }
        let estimatedDate = estimated.flatMap { apiFormatter.date(from: $0) }
        let scheduledDate = scheduled.flatMap { apiFormatter.date(from: $0) }
        
        // Calculate time difference
        var isEarly = false
        var isDelayed = false
        var minutesDifference: Int? = nil
        
        if let estimatedDate = estimatedDate, let scheduledDate = scheduledDate {
            let difference = scheduledDate.timeIntervalSince(estimatedDate)
            if difference > 0 {
                isEarly = true
                minutesDifference = Int(difference / 60)
            } else if difference < 0 {
                isDelayed = true
                minutesDifference = Int(abs(difference / 60))
            }
        }
        
        // Prioritize actual time if available
        if let actualDate = actualDate {
            return FlightTime(
                displayTime: timeFormatter.string(from: actualDate),
                displayTimezone: displayTimezone,
                actualTime: timeFormatter.string(from: actualDate),
                scheduledTime: scheduledDate.map { timeFormatter.string(from: $0) },
                estimatedTime: estimatedDate.map { timeFormatter.string(from: $0) },
                date: dateFormatter.string(from: actualDate),
                isEarly: isEarly,
                isDelayed: isDelayed,
                minutesDifference: minutesDifference,
                cancelled: isCancelled
            )
        }
        
        // Fall back to estimated time
        if let estimatedDate = estimatedDate {
            return FlightTime(
                displayTime: timeFormatter.string(from: estimatedDate),
                displayTimezone: displayTimezone,
                actualTime: nil,
                scheduledTime: scheduledDate.map { timeFormatter.string(from: $0) },
                estimatedTime: timeFormatter.string(from: estimatedDate),
                date: dateFormatter.string(from: estimatedDate),
                isEarly: isEarly,
                isDelayed: isDelayed,
                minutesDifference: minutesDifference,
                cancelled: isCancelled
            )
        }
        
        // Fallback to scheduled time
        if let scheduledDate = scheduledDate {
            return FlightTime(
                displayTime: timeFormatter.string(from: scheduledDate),
                displayTimezone: displayTimezone,
                actualTime: nil,
                scheduledTime: timeFormatter.string(from: scheduledDate),
                estimatedTime: nil,
                date: dateFormatter.string(from: scheduledDate),
                isEarly: false,
                isDelayed: false,
                minutesDifference: nil,
                cancelled: isCancelled
            )
        }
        
        return FlightTime(
            displayTime: "--:--",
            displayTimezone: displayTimezone,
            actualTime: nil,
            scheduledTime: nil,
            estimatedTime: nil,
            date: "---",
            isEarly: false,
            isDelayed: false,
            minutesDifference: nil,
            cancelled: isCancelled
        )
    }
}
