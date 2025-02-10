//
//  FlightViewModel.swift
//  FlightApp
//
//  Created by Kush Shah on 2/9/25.
//

import Foundation

@MainActor
class FlightViewModel: ObservableObject {
    @Published var currentFlight: AeroFlight?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var noFlightsFound = false
    
    func searchFlight(flightNumber: String) {
        isLoading = true
        error = nil
        noFlightsFound = false
        
        Task {
            do {
                print("🔎 Searching for flight: \(flightNumber)")
                let response = try await AeroAPIService.shared.searchFlight(flightNumber)
                print("✅ Got response with \(response.flights.count) flights")
                
                if let flight = response.flights.first {
                    print("🛩 Found flight: \(flight.ident)")
                    self.currentFlight = flight
                } else {
                    print("⚠️ No active flights found")
                    self.noFlightsFound = true
                }
            } catch {
                print("❌ Error: \(error)")
                self.error = error
            }
            isLoading = false
        }
    }
    
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
                    let response = try await AeroAPIService.shared.searchFlight(flightNumber)
                    print("✅ Got response with \(response.flights.count) flights")
                    
                    if let flight = response.flights.first {
                        print("🛩 Found flight: \(flight.ident)")
                        self.currentFlight = flight
                    } else {
                        print("⚠️ No flights found in response")
                    }
                } catch {
                    print("❌ Error: \(error)")
                    self.error = error
                }
                isLoading = false
            }
        }
    }
}
