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
                departureDelay: flight.departureDelay,
                arrivalDelay: flight.arrivalDelay,
                isCancelled: flight.cancelled
            )
            
            let arrival = formatTimeWithZone(
                actual: flight.actualOn,
                estimated: flight.estimatedOn,
                scheduled: flight.scheduledOn,
                timezone: flight.destination.timezone ?? "UTC",
                departureDelay: flight.departureDelay,
                arrivalDelay: flight.arrivalDelay,
                isCancelled: flight.cancelled
            )
            
            return (departure, arrival)
        }
    }
    
    
private func formatTimeWithZone(
    actual: String?,
    estimated: String?,
    scheduled: String?,
    timezone: String,
    departureDelay: Int? = nil,
    arrivalDelay: Int? = nil,
    isCancelled: Bool = false
) -> FlightTime {
    let apiFormatter = ISO8601DateFormatter.standardFormatter()
    
    // Get the timezone for this flight
    let timeZone = TimeZone(identifier: timezone) ?? TimeZone.current
    
    // Get all date versions
    let actualDate = actual.flatMap { apiFormatter.date(from: $0) }
    let estimatedDate = estimated.flatMap { apiFormatter.date(from: $0) }
    let scheduledDate = scheduled.flatMap { apiFormatter.date(from: $0) }
    
    // Calculate adjusted scheduled time if we have a delay but no actual time
    var adjustedScheduledDate: Date? = nil
    if actualDate == nil,
       let scheduledDate = scheduledDate,
       let delay = departureDelay {
        adjustedScheduledDate = scheduledDate.addingTimeInterval(Double(delay))
    }
    
    // Determine delay status
    var isEarly = false
    var isDelayed = false
    var minutesDifference: Int? = nil
    
    // Use provided delay information if available
    if let departureDelay = departureDelay {
        if departureDelay > 0 {
            isDelayed = true
            minutesDifference = departureDelay / 60
        } else if departureDelay < 0 {
            isEarly = true
            minutesDifference = abs(departureDelay / 60)
        }
    } else if let estimatedDate = estimatedDate, let scheduledDate = scheduledDate {
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
            displayTime: actualDate.formattedTime(in: timeZone),
            displayTimezone: actualDate.formattedTimezone(timezone: timeZone),
            actualTime: actualDate.formattedTime(in: timeZone),
            scheduledTime: scheduledDate?.formattedTime(in: timeZone),
            estimatedTime: estimatedDate?.formattedTime(in: timeZone),
            date: actualDate.formattedDate(in: timeZone),
            isEarly: isEarly,
            isDelayed: isDelayed,
            minutesDifference: minutesDifference,
            cancelled: isCancelled
        )
    }
    
    // Use adjusted scheduled time if available
    if let adjustedScheduledDate = adjustedScheduledDate,
       let scheduledDate = scheduledDate {
        return FlightTime(
            displayTime: scheduledDate.formattedTime(in: timeZone),
            displayTimezone: scheduledDate.formattedTimezone(timezone: timeZone),
            actualTime: adjustedScheduledDate.formattedTime(in: timeZone),
            scheduledTime: scheduledDate.formattedTime(in: timeZone),
            estimatedTime: nil,
            date: scheduledDate.formattedDate(in: timeZone),
            isEarly: isEarly,
            isDelayed: isDelayed,
            minutesDifference: minutesDifference,
            cancelled: isCancelled
        )
    }
    
    // Fall back to estimated time
    if let estimatedDate = estimatedDate {
        return FlightTime(
            displayTime: estimatedDate.formattedTime(in: timeZone),
            displayTimezone: estimatedDate.formattedTimezone(timezone: timeZone),
            actualTime: nil,
            scheduledTime: scheduledDate?.formattedTime(in: timeZone),
            estimatedTime: estimatedDate.formattedTime(in: timeZone),
            date: estimatedDate.formattedDate(in: timeZone),
            isEarly: isEarly,
            isDelayed: isDelayed,
            minutesDifference: minutesDifference,
            cancelled: isCancelled
        )
    }
    
    // Fallback to scheduled time
    if let scheduledDate = scheduledDate {
        return FlightTime(
            displayTime: scheduledDate.formattedTime(in: timeZone),
            displayTimezone: scheduledDate.formattedTimezone(timezone: timeZone),
            actualTime: nil,
            scheduledTime: scheduledDate.formattedTime(in: timeZone),
            estimatedTime: nil,
            date: scheduledDate.formattedDate(in: timeZone),
            isEarly: false,
            isDelayed: false,
            minutesDifference: nil,
            cancelled: isCancelled
        )
    }
    
    // Final fallback with no times available
    return FlightTime(
        displayTime: "--:--",
        displayTimezone: timeZone.abbreviation() ?? "UTC",
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
