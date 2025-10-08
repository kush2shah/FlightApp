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
                VStack(spacing: 0) {
                    if let flight = viewModel.currentFlight {
                        // Hero section with flight number and route
                        FlightHeroSection(flight: flight)
                            .padding(.horizontal)
                            .padding(.top)

                        // Route map - full width, no padding
                        FlightRouteMapView(flight: flight)
                            .padding(.top, 20)

                        VStack(spacing: 20) {
                            // Time and progress information
                            let flightTimes = viewModel.getFlightTimes()
                            FlightRouteCard(
                                flight: flight,
                                times: flightTimes
                            )

                            // Gate and terminal information
                            FlightGateTerminalCard(flight: flight)

                            // Aircraft and route details
                            FlightAircraftCard(flight: flight)

                            // Airline profile section
                            airlineProfileSection

                            // Status view (if not cancelled)
                            if !flight.cancelled {
                                FlightStatusView(flight: flight)
                            }

                            // Additional flight details
                            if !flight.cancelled {
                                FlightDetailsSection(flight: flight)
                            }
                        }
                        .padding()
                    } else if viewModel.isLoading {
                        LoadingView(flightNumber: flightNumber)
                            .padding()
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
                        .padding()
                    }
                }
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
    
    private var groupedFlights: [(String, [AeroFlight])] {
        let sorted = flights.sorted { first, second in
            let firstDate = first.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) } ?? .distantFuture
            let secondDate = second.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) } ?? .distantFuture
            return firstDate < secondDate
        }
        
        let grouped = Dictionary(grouping: sorted) { flight in
            guard let scheduledOut = flight.scheduledOut,
                  let date = ISO8601DateFormatter().date(from: scheduledOut),
                  let timezone = TimeZone(identifier: flight.origin.timezone ?? "UTC") else {
                return "Unknown Date"
            }
            return date.smartRelativeDate(in: timezone)
        }
        
        return grouped.sorted { first, second in
            let dateOrder = ["Today", "Tomorrow", "Yesterday"]
            let firstIndex = dateOrder.firstIndex(of: first.key) ?? Int.max
            let secondIndex = dateOrder.firstIndex(of: second.key) ?? Int.max
            
            if firstIndex != Int.max && secondIndex != Int.max {
                return firstIndex < secondIndex
            } else if firstIndex != Int.max {
                return true
            } else if secondIndex != Int.max {
                return false
            } else {
                return first.key < second.key
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(groupedFlights, id: \.0) { dateGroup, flights in
                        VStack(alignment: .leading, spacing: 12) {
                            // Date section header
                            HStack {
                                Text(dateGroup)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(flights.count) flight\(flights.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Flights for this date
                            ForEach(flights, id: \.faFlightId) { flight in
                                Button {
                                    print("🔵 Selected flight: \(flight.ident)")
                                    onSelect(flight)
                                    dismiss()
                                } label: {
                                    EnhancedFlightSelectionCard(flight: flight)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Flight")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EnhancedFlightSelectionCard: View {
    let flight: AeroFlight
    
    private var flightTime: String {
        guard let scheduledOut = flight.scheduledOut,
              let date = ISO8601DateFormatter().date(from: scheduledOut),
              let timezone = TimeZone(identifier: flight.origin.timezone ?? "UTC") else {
            return "--:--"
        }
        return date.formattedTime(in: timezone)
    }
    
    private var statusInfo: (text: String, color: Color) {
        if flight.cancelled {
            return ("Cancelled", .red)
        }
        
        if flight.isInProgress {
            return ("In Progress", .green)
        }
        
        if let departureDelay = flight.departureDelay, departureDelay > 0 {
            let minutes = departureDelay / 60
            return ("Delayed \(minutes)m", .orange)
        }
        
        if let scheduledOut = flight.scheduledOut,
           let date = ISO8601DateFormatter().date(from: scheduledOut),
           date > Date() {
            return ("Scheduled", .blue)
        }
        
        return ("On Time", .green)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Flight header with time and status
            HStack {
                VStack(alignment: .leading) {
                    Text("\(flight.operatorIata ?? flight.operator_ ?? "") \(flight.flightNumber ?? flight.ident)")
                        .font(.headline)
                    Text(flightTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(statusInfo.text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusInfo.color.opacity(0.2))
                    .foregroundColor(statusInfo.color)
                    .cornerRadius(6)
            }
            
            // Route information
            HStack {
                VStack(alignment: .leading) {
                    Text(flight.origin.displayCode)
                        .font(.headline)
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
                        .font(.headline)
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
}

#Preview {
    FlightView(flightNumber: "3K685")
}
