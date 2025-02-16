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
    
    func selectFlight(_ flight: AeroFlight) {
        self.currentFlight = flight
        self.showFlightSelection = false
    }
    
    func searchFlight(flightNumber: String) {
        guard !flightNumber.isEmpty else {
            self.error = AeroAPIError.invalidURL
            return
        }
        
        isLoading = true
        error = nil
        currentFlight = nil  // Reset current flight
        
        Task {
            do {
                print("🔎 Searching for flight: \(flightNumber)")
                let flights = try await AeroAPIService.shared.getFlightInfo(flightNumber)
                
                self.availableFlights = flights
                
                // If there's only one flight, select it automatically
                if flights.count == 1 {
                    self.currentFlight = flights[0]
                } else if !flights.isEmpty {
                    // If there are multiple flights, show the selection sheet
                    self.showFlightSelection = true
                }
                
            } catch {
                print("❌ Error: \(error)")
                self.error = error
            }
            
            isLoading = false
        }
    }
}
