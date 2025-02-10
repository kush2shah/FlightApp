//
//  FlightView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/10/25.
//

import SwiftUI

struct FlightView: View {
    @StateObject private var viewModel = FlightViewModel()
    let flightNumber: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Main flight card with route visualization
                if let flight = viewModel.currentFlight {
                    FlightRouteCard(flight: flight)
                        .padding(.horizontal)
                    
                    // Flight stats if we have position data
                    if let position = flight.lastPosition {
                        FlightStatsSection(position: position)
                            .padding(.horizontal)
                    }
                    
                    // Timeline of events
                    FlightTimelineSection(flight: flight)
                        .padding(.horizontal)
                    
                    // Weather at destination
                    WeatherSection(city: flight.destination.city)
                        .padding(.horizontal)
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.noFlightsFound {
                    VStack(spacing: 12) {
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Active Flights Found")
                            .font(.headline)
                        Text("Flight \(flightNumber) is not currently in the air")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let error = viewModel.error {
                    VStack(spacing: 12) {
                        Text("Unable to load flight information")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .padding(.top)
            .padding(.bottom, 100) // Add extra padding for bottom bar
        }
        .onAppear {
            viewModel.searchFlight(flightNumber: flightNumber)
        }
    }
}

struct FlightRouteCard: View {
    let flight: AeroFlight
    
    var body: some View {
        VStack(spacing: 24) {
            // Airline info
            HStack {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("United Airlines")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(flight.ident)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("On Time")
                    .font(.subheadline)
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            // Route visualization
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(flight.origin.code)
                            .font(.system(size: 32, weight: .bold))
                        Text(flight.origin.city)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(flight.destination.code)
                            .font(.system(size: 32, weight: .bold))
                        Text(flight.destination.city)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Flight path
                ZStack(alignment: .center) {
                    // Path line
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Plane indicator
                    Image(systemName: "airplane")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(45))
                        .offset(x: -20)
                }
                .padding(.horizontal)
                
                // Time info
                HStack {
                    VStack(alignment: .leading) {
                        Text(flight.actualOff ?? "TBD")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text("Departure")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("11h 25m")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(flight.actualOn ?? "TBD")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text("Arrival")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(radius: 10)
    }
}

struct FlightStatsSection: View {
    let position: AeroPosition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flight Stats")
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                StatCard(
                    icon: "speedometer",
                    value: "\(position.groundspeed)",
                    unit: "mph",
                    color: .blue
                )
                
                StatCard(
                    icon: "arrow.up.forward",
                    value: "\(position.altitude)",
                    unit: "ft",
                    color: .purple
                )
                
                StatCard(
                    icon: "arrow.up",
                    value: "\(position.heading)°",
                    unit: "hdg",
                    color: .orange
                )
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

struct FlightTimelineSection: View {
    let flight: AeroFlight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flight Timeline")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 24) {
                TimelineEvent(
                    time: flight.actualOff ?? "TBD",
                    event: "Departure",
                    detail: "Gate TBD",
                    isDone: flight.actualOff != nil
                )
                
                TimelineEvent(
                    time: "In Progress",
                    event: flight.lastPosition != nil ? "En Route" : "Not Departed",
                    detail: flight.lastPosition != nil ? "On Time" : "Scheduled",
                    isDone: flight.lastPosition != nil
                )
                
                TimelineEvent(
                    time: flight.actualOn ?? "TBD",
                    event: "Arrival",
                    detail: "Gate TBD",
                    isDone: flight.actualOn != nil
                )
            }
        }
    }
}

struct TimelineEvent: View {
    let time: String
    let event: String
    let detail: String
    let isDone: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Time
            Text(time)
                .font(.subheadline)
                .frame(width: 80, alignment: .trailing)
            
            // Status indicator
            Circle()
                .fill(isDone ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 12.0, height: 12.0)
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WeatherSection: View {
    let city: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Destination Weather")
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(city)
                        .font(.headline)
                    Text("Weather data coming soon")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    
                    Text("--°C")
                        .font(.system(size: 32, weight: .medium))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 5)
        }
    }
}

#Preview {
    FlightView(flightNumber: "3K685")
}
