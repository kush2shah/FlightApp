//
//  FlightViewModel.swift
//  FlightApp
//
//  Created by Kush Shah on 2/9/25.
//

import SwiftUI

@MainActor
class FlightViewModel: ObservableObject {
    @Published var availableFlights: [AeroFlight] = []
    @Published var currentFlight: AeroFlight?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showFlightSelection = false
    @Published var airlineProfile: AirlineProfile?
    @Published var isLoadingAirline = false
    @Published var airlineError: Error?
    var skipFlightSelection = false
    private var lastSearchedFlightNumber: String?

    func searchFlightForDate(_ date: Date) {
        guard let flightNumber = lastSearchedFlightNumber else { return }

        isLoading = true
        error = nil

        Task {
            do {
                print("🔎 Re-searching for flight: \(flightNumber) on \(date)")
                let flights = try await AeroAPIService.shared.getFlightInfo(flightNumber, startDate: date)
                print("✅ Found \(flights.count) flights")

                await MainActor.run {
                    self.availableFlights = flights

                    if !flights.isEmpty {
                        print("📱 Updated flight selection with new results")
                        // Keep sheet open with updated results
                    }
                }
            } catch {
                print("❌ Error: \(error)")
                await MainActor.run {
                    self.error = error
                }
            }

            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func selectFlight(_ flight: AeroFlight) {
        print("📱 Selecting flight: \(flight.ident)")
        self.currentFlight = flight
        self.showFlightSelection = false
    }
    
    func searchFlight(flightNumber: String, faFlightId: String? = nil) {
        guard !flightNumber.isEmpty else {
            self.error = AeroAPIError.invalidURL
            return
        }

        // Prevent duplicate searches only if currently loading the same flight
        if lastSearchedFlightNumber == flightNumber && isLoading {
            print("⏭️ Skipping duplicate search (already loading): \(flightNumber)")
            return
        }

        // Allow re-search if we don't have a current flight yet
        lastSearchedFlightNumber = flightNumber
        isLoading = true
        error = nil
        currentFlight = nil

        Task {
            do {
                print("🔎 Searching for flight: \(flightNumber)")
                let flights = try await AeroAPIService.shared.getFlightInfo(flightNumber)
                print("✅ Found \(flights.count) flights")

                await MainActor.run {
                    self.availableFlights = flights

                    if !flights.isEmpty {
                        // If we have a specific fa_flight_id, select that exact flight
                        if let faFlightId = faFlightId,
                           let specificFlight = flights.first(where: { $0.faFlightId == faFlightId }) {
                            print("📱 Auto-selecting specific flight by fa_flight_id: \(faFlightId)")
                            self.currentFlight = specificFlight
                        } else if skipFlightSelection {
                            // Auto-select first flight when opened from another view
                            print("📱 Auto-selecting flight (skipFlightSelection=true)")
                            self.currentFlight = flights[0]
                        } else {
                            // Show selection sheet to give access to date picker
                            print("📱 Showing flight selection sheet for \(flights.count) flight(s)")
                            self.showFlightSelection = true
                        }
                    }
                }
            } catch {
                print("❌ Error: \(error)")
                await MainActor.run {
                    self.error = error
                }
            }

            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func getFlightTimes() -> (departure: FlightTime, arrival: FlightTime) {
        guard let flight = currentFlight else {
            return (
                FlightTime(displayTime: "--:--", displayTimezone: "UTC", date: "---", isEarly: false, isDelayed: false, cancelled: false),
                FlightTime(displayTime: "--:--", displayTimezone: "UTC", date: "---", isEarly: false, isDelayed: false, cancelled: false)
            )
        }
        
        let departure = formatTimeWithZone(
            actual: flight.actualOut,
            estimated: flight.estimatedOut,
            scheduled: flight.scheduledOut,
            timezone: flight.origin.timezone ?? "UTC",
            departureDelay: flight.departureDelay,
            isCancelled: flight.cancelled
        )
        
        let arrival = formatTimeWithZone(
            actual: flight.actualOn,
            estimated: flight.estimatedOn,
            scheduled: flight.scheduledOn,
            timezone: flight.destination.timezone ?? "UTC",
            arrivalDelay: flight.arrivalDelay,
            isCancelled: flight.cancelled
        )
        
        return (departure, arrival)
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
        let timeZone = TimeZone(identifier: timezone) ?? TimeZone.current
        
        let actualDate = actual.flatMap { apiFormatter.date(from: $0) }
        let estimatedDate = estimated.flatMap { apiFormatter.date(from: $0) }
        let scheduledDate = scheduled.flatMap { apiFormatter.date(from: $0) }
        
        var isEarly = false
        var isDelayed = false
        var minutesDifference: Int? = nil
        
        if let delay = departureDelay ?? arrivalDelay {
            if delay > 0 {
                isDelayed = true
                minutesDifference = delay / 60
            } else if delay < 0 {
                isEarly = true
                minutesDifference = abs(delay / 60)
            }
        }
        
        if let actualDate = actualDate {
            return FlightTime(
                displayTime: actualDate.formattedTime(in: timeZone),
                displayTimezone: actualDate.formattedTimezone(timezone: timeZone),
                actualTime: actualDate.formattedTime(in: timeZone),
                scheduledTime: scheduledDate?.formattedTime(in: timeZone),
                estimatedTime: estimatedDate?.formattedTime(in: timeZone),
                date: actualDate.formattedDate(in: timeZone),
                fullDate: actualDate,
                timezone: timeZone,
                isEarly: isEarly,
                isDelayed: isDelayed,
                minutesDifference: minutesDifference,
                cancelled: isCancelled
            )
        }
        
        if let estimatedDate = estimatedDate {
            return FlightTime(
                displayTime: estimatedDate.formattedTime(in: timeZone),
                displayTimezone: estimatedDate.formattedTimezone(timezone: timeZone),
                actualTime: nil,
                scheduledTime: scheduledDate?.formattedTime(in: timeZone),
                estimatedTime: estimatedDate.formattedTime(in: timeZone),
                date: estimatedDate.formattedDate(in: timeZone),
                fullDate: estimatedDate,
                timezone: timeZone,
                isEarly: isEarly,
                isDelayed: isDelayed,
                minutesDifference: minutesDifference,
                cancelled: isCancelled
            )
        }
        
        if let scheduledDate = scheduledDate {
            return FlightTime(
                displayTime: scheduledDate.formattedTime(in: timeZone),
                displayTimezone: scheduledDate.formattedTimezone(timezone: timeZone),
                actualTime: nil,
                scheduledTime: scheduledDate.formattedTime(in: timeZone),
                estimatedTime: nil,
                date: scheduledDate.formattedDate(in: timeZone),
                fullDate: scheduledDate,
                timezone: timeZone,
                isEarly: false,
                isDelayed: false,
                minutesDifference: nil,
                cancelled: isCancelled
            )
        }
        
        return FlightTime(
            displayTime: "--:--",
            displayTimezone: timeZone.abbreviation() ?? "UTC",
            actualTime: nil,
            scheduledTime: nil,
            estimatedTime: nil,
            date: "---",
            fullDate: nil,
            timezone: timeZone,
            isEarly: false,
            isDelayed: false,
            minutesDifference: nil,
            cancelled: isCancelled
        )
    }
    
    func formatDelay(_ seconds: Int) -> String {
            let absSeconds = abs(seconds)
            let hours = absSeconds / 3600
            let minutes = (absSeconds % 3600) / 60
            
            if hours > 0 {
                if minutes > 0 {
                    return "\(hours)h \(minutes)m"
                }
                return "\(hours)h"
            }
            return "\(minutes)m"
        }
    
    func fetchAirlineInfo() {
            guard let flight = currentFlight,
                  let airlineCode = AirlineService.shared.getAirlineCodeFromFlight(flight) else {
                return
            }
            
            isLoadingAirline = true
            airlineError = nil
            
            Task {
                do {
                    print("🔎 Fetching airline info for: \(airlineCode)")
                    let profile = try await AirlineService.shared.getAirlineInfo(code: airlineCode)
                    
                    await MainActor.run {
                        self.airlineProfile = profile
                        self.isLoadingAirline = false
                    }
                } catch {
                    print("❌ Error fetching airline: \(error)")
                    await MainActor.run {
                        self.airlineError = error
                        self.isLoadingAirline = false
                    }
                }
            }
        }
}

extension Int {
    func formattedDelay() -> String {
        let absSeconds = abs(self)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
}

