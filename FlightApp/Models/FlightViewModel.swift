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
        isLoading = true
        error = nil
        
        Task {
            do {
                print("🔎 Searching for flight: \(flightNumber)")
                let response = try await AeroAPIService.shared.getFlightInfo(flightNumber)
                
                if let flight = response.flights.first {
                    print("✅ Found flight: \(flight.ident)")
                    self.currentFlight = flight
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
        guard let flight = currentFlight else {
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
    
    func getFlightTimes() -> (departure: String, arrival: String) {
        guard let flight = currentFlight else {
            return ("TBD", "TBD")
        }
        
        let departureTime = formatTime(flight.actualOff ?? flight.estimatedOff ?? flight.scheduledOff)
        let arrivalTime = formatTime(flight.actualOn ?? flight.estimatedOn ?? flight.scheduledOn)
        
        return (departureTime, arrivalTime)
    }
    
    private func formatTime(_ timestamp: String?) -> String {
        guard let timestamp = timestamp else { return "TBD" }
        
        let apiFormatter = ISO8601DateFormatter()
        apiFormatter.formatOptions = [.withInternetDateTime]
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        
        if let date = apiFormatter.date(from: timestamp) {
            return displayFormatter.string(from: date)
        }
        
        return "TBD"
    }
}
