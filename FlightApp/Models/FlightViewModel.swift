//
//  FlightViewModel.swift
//  FlightApp
//
//  Created by Kush Shah on 2/9/25.
//

import SwiftUI

@MainActor
class FlightViewModel: ObservableObject {
    @Published var flightDetails: AeroFlightDetails?
    @Published var isLoading = false
    @Published var error: Error?
    
    func searchFlight(flightNumber: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                print("🔎 Searching for flight: \(flightNumber)")
                let response = try await AeroAPIService.shared.getFlightInfo(flightNumber)
                
                if let flight = response.flights.first {
                    print("✅ Found flight: \(flight.ident)")
                    self.flightDetails = flight
                } else {
                    print("⚠️ No flights found in response")
                    self.error = AeroAPIError.noFlightsFound
                }
            } catch {
                print("❌ Error: \(error)")
                self.error = error
            }
            
            isLoading = false
        }
    }
    
    func getFlightStatus() -> (status: String, color: Color) {
        guard let flight = flightDetails else {
            return ("Unknown", .secondary)
        }
        
        if flight.cancelled {
            return ("Cancelled", .red)
        }
        
        if flight.diverted {
            return ("Diverted", .orange)
        }
        
        // Check if flight has departed
        if flight.actualOff != nil {
            if flight.actualOn != nil {
                return ("Landed", .green)
            }
            return ("In Air", .blue)
        }
        
        // Check if flight is delayed
        if let delay = flight.departureDelay, delay > 900 { // 15 minutes
            return ("Delayed", .orange)
        }
        
        return ("Scheduled", .green)
    }
    
    func getFormattedTime(_ timestamp: String?) -> String {
        guard let timestamp = timestamp else { return "TBD" }
        
        // Create date formatter for parsing API timestamps
        let apiFormatter = ISO8601DateFormatter()
        apiFormatter.formatOptions = [.withInternetDateTime]
        
        // Create formatter for displaying times
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        
        if let date = apiFormatter.date(from: timestamp) {
            return displayFormatter.string(from: date)
        }
        
        return "TBD"
    }
    
    func getFlightTimes() -> (departure: String, arrival: String) {
        guard let flight = flightDetails else {
            return ("TBD", "TBD")
        }
        
        // Use actual times if available, fall back to estimated, then scheduled
        let departureTime = getFormattedTime(flight.actualOff ?? flight.estimatedOff ?? flight.scheduledOff)
        let arrivalTime = getFormattedTime(flight.actualOn ?? flight.estimatedOn ?? flight.scheduledOn)
        
        return (departureTime, arrivalTime)
    }
}
