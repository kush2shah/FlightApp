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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let flight = viewModel.currentFlight {
                        FlightHeaderView(flight: flight)
                        
                        FlightStatusView(flight: flight)
                        
                        FlightRouteCard(
                            flight: flight,
                            times: (
                                departure: viewModel.getFlightTimes().departure,
                                arrival: viewModel.getFlightTimes().arrival
                            )
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
        }
        .onAppear {
            viewModel.searchFlight(flightNumber: flightNumber)
        }
    }
}

struct FlightHeaderView: View {
    let flight: AeroFlight
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        if let operatorName = flight.operatorIata ?? flight.operator_ {
                            Text(operatorName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Text(flight.flightNumber ?? flight.ident)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    if let type = flight.aircraftType {
                        Text(type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct LoadingView: View {
    let flightNumber: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching for flight \(flightNumber)...")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    FlightView(flightNumber: "3K685")
}
