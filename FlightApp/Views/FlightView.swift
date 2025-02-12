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
            ZStack {
                if let flight = viewModel.currentFlight {
                    FlightContent(
                        flight: flight,
                        status: viewModel.getFlightStatus(),
                        times: viewModel.getFlightTimes()
                    )
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
            .navigationTitle("Flight \(flightNumber)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.searchFlight(flightNumber: flightNumber)
        }
    }
}

struct FlightContent: View {
    let flight: AeroFlight
    let status: (status: String, color: Color)
    let times: (departure: String, arrival: String)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                FlightHeader(flight: flight, status: status)
                FlightRouteCard(flight: flight, times: times)
                
                if !flight.cancelled {
                    FlightDetailsSection(flight: flight)
                }
            }
            .padding(.vertical)
        }
    }
}

struct LoadingView: View {
    let flightNumber: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Looking for flight \(flightNumber)...")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    FlightView(flightNumber: "3K685")
}
