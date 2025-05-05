//
//  EnhancedFlightView.swift
//  FlightApp
//
//  Created by Kush Shah on 5/4/25.
//

import SwiftUI

struct EnhancedFlightView: View {
    @AppStorage("useEnhancedMode") private var useEnhancedMode = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FlightViewModel
    let flightNumber: String
    let skipFlightSelection: Bool
    
    init(flightNumber: String, skipFlightSelection: Bool = false) {
        self.flightNumber = flightNumber
        self.skipFlightSelection = skipFlightSelection
        
        // Initialize the view model
        _viewModel = StateObject(wrappedValue: FlightViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let flight = viewModel.currentFlight {
                        FlightHeaderView(flight: flight)
                        
                        // Airline profile section
                        airlineProfileSection
                        
                        // Enhanced Flight Status
                        if useEnhancedMode {
                            FlightStatusView(flight: flight)
                                .withEnhancedVisualizations(flight: flight, airline: viewModel.airlineProfile)
                        } else {
                            FlightStatusView(flight: flight)
                        }
                        
                        // Flight route card
                        let flightTimes = viewModel.getFlightTimes()
                        FlightRouteCard(
                            flight: flight,
                            times: flightTimes
                        )
                        
                        // Enhanced flight details with points integration
                        if !flight.cancelled {
                            if useEnhancedMode {
                                FlightDetailsSection(flight: flight)
                                    .withPointsIntegration(flight: flight, airline: viewModel.airlineProfile)
                            } else {
                                FlightDetailsSection(flight: flight)
                            }
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
            .toolbar {
                // Add a toggle for enhanced mode in the toolbar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        useEnhancedMode.toggle()
                    }) {
                        if useEnhancedMode {
                            Label("Standard Mode", systemImage: "rectangle.on.rectangle")
                        } else {
                            Label("Enhanced Mode", systemImage: "sparkles")
                        }
                    }
                }
            }
        }
        .onAppear {
            // Setup the view model
            viewModel.skipFlightSelection = skipFlightSelection
            viewModel.searchFlight(flightNumber: flightNumber)
            
            // Check for current flight and fetch airline info if needed
            if viewModel.currentFlight != nil && viewModel.airlineProfile == nil {
                viewModel.fetchAirlineInfo()
            }
        }
        // Respond to flight changes
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

#Preview {
    EnhancedFlightView(flightNumber: "UA123")
}
