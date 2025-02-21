//
//  FlightView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/10/25.
//

import SwiftUI

struct FlightView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FlightViewModel()
    let flightNumber: String
    let skipFlightSelection: Bool
    
    // Add an initializer with default parameter
    init(flightNumber: String, skipFlightSelection: Bool = false) {
        self.flightNumber = flightNumber
        self.skipFlightSelection = skipFlightSelection
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let flight = viewModel.currentFlight {
                        FlightHeaderView(flight: flight)
                        
                        // Add airline profile section here
                        airlineProfileSection
                        
                        FlightStatusView(flight: flight)
                        
                        // Get times once and reuse
                        let flightTimes = viewModel.getFlightTimes()
                        FlightRouteCard(
                            flight: flight,
                            times: flightTimes
                        )
                        
                        if !flight.cancelled {
                            FlightDetailsSection(flight: flight)
                        }
                    } else if viewModel.isLoading {
                        LoadingView(flightNumber: flightNumber)
                    } else if let error = viewModel.error {
                        FlightErrorView(
                            flightNumber: flightNumber,
                            errorMessage: error.localizedDescription,
                            onRetry: {
                                viewModel.searchFlight(flightNumber: flightNumber)
                            },
                            onBack: {
                                dismiss()
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Flight \(flightNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showFlightSelection) {
                FlightSelectionSheet(
                    flights: viewModel.availableFlights,
                    onSelect: viewModel.selectFlight
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            viewModel.skipFlightSelection = skipFlightSelection
            viewModel.searchFlight(flightNumber: flightNumber)
            
            // Check for current flight and fetch airline info if needed
            if viewModel.currentFlight != nil && viewModel.airlineProfile == nil {
                viewModel.fetchAirlineInfo()
            }
        }
        // Use a different approach to respond to flight changes
        .onChange(of: viewModel.currentFlight?.faFlightId) { _ in
            if viewModel.currentFlight != nil {
                viewModel.fetchAirlineInfo()
            }
        }
    }
    
    // Airline profile section with loading states
    private var airlineProfileSection: some View {
        Group {
            if viewModel.isLoadingAirline {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let airline = viewModel.airlineProfile {
                AirlineProfileView(airline: airline)
            } else if viewModel.airlineError != nil {
                // Show minimal fallback with just the airline code if we couldn't load details
                minimalAirlineInfo
            } else {
                // Show minimal airline info while waiting to load
                minimalAirlineInfo
            }
        }
    }
    
    // Minimal airline info shown as fallback
    private var minimalAirlineInfo: some View {
        Group {
            if let flight = viewModel.currentFlight,
               let airlineCode = flight.operatorIcao ?? flight.operatorIata ?? flight.operator_ {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Operator")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(airlineCode)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

struct FlightSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    let flights: [AeroFlight]
    let onSelect: (AeroFlight) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(flights, id: \.faFlightId) { flight in
                        Button {
                            print("🔵 Selected flight: \(flight.ident)")
                            onSelect(flight)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                // Flight identifier and status
                                HStack {
                                    Text("\(flight.operatorIata ?? flight.operator_ ?? "") \(flight.flightNumber ?? flight.ident)")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if flight.isInProgress {
                                        Text("In Progress")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                // Times
                                if let scheduledOut = flight.scheduledOut,
                                   let date = ISO8601DateFormatter().date(from: scheduledOut) {
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Route information
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(flight.origin.displayCode)
                                        Text(flight.origin.city ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "airplane")
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(flight.destination.displayCode)
                                        Text(flight.destination.city ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Select Flight")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FlightView(flightNumber: "3K685")
}
