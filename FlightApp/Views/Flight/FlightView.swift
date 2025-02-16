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
            viewModel.searchFlight(flightNumber: flightNumber)
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
            isEarly: false,
            isDelayed: false,
            minutesDifference: nil,
            cancelled: isCancelled
        )
    }


// Status badge component
struct FlightStatusBadge: View {
    var body: some View {
        Text("In Progress")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
            .cornerRadius(4)
    }
}

// Route information component
struct RouteInformationView: View {
    let flight: AeroFlight
    
    var body: some View {
        HStack {
            AirportView(
                code: flight.origin.displayCode,
                city: flight.origin.city ?? "",
                alignment: .leading
            )
            
            Spacer()
            
            Image(systemName: "airplane")
                .foregroundColor(.secondary)
            
            Spacer()
            
            AirportView(
                code: flight.destination.displayCode,
                city: flight.destination.city ?? "",
                alignment: .trailing
            )
        }
    }
}

// Airport information component
struct AirportView: View {
    let code: String
    let city: String
    let alignment: HorizontalAlignment
    
    var body: some View {
        VStack(alignment: alignment) {
            Text(code)
            Text(city)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Codeshare information component
struct CodeshareInformationView: View {
    let codeshares: [String]?
    
    var body: some View {
        if let codeshares = codeshares, !codeshares.isEmpty {
            Text("Also known as: \(codeshares.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
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
