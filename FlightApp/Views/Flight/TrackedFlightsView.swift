//
//  TrackedFlightsView.swift
//  FlightApp
//
//  Main view for displaying all tracked flights with map background
//

import SwiftUI

struct TrackedFlightsView: View {
    @StateObject private var store = TrackedFlightsStore()
    @State private var selectedFlight: TrackedFlight?
    @State private var showFlightDetail = false

    var body: some View {
        ZStack {
            // Map background with great circle paths
            if !store.trackedFlights.isEmpty {
                TrackedFlightsMapView(trackedFlights: store.trackedFlights)
                    .ignoresSafeArea()
            } else {
                // Empty state background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
            }

            // Main content
            VStack(spacing: 0) {
                // Navigation bar area (semi-transparent)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Tracked Flights")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.primary)

                        Spacer()

                        if !store.trackedFlights.isEmpty {
                            Text("\(store.trackedFlights.count)")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.regularMaterial)
                                )
                        }
                    }

                    // Filter tabs
                    if !store.trackedFlights.isEmpty {
                        HStack(spacing: 12) {
                            FilterTab(
                                title: "All",
                                count: store.trackedFlights.count,
                                isSelected: true
                            )

                            if !store.activeFlights.isEmpty {
                                FilterTab(
                                    title: "Active",
                                    count: store.activeFlights.count,
                                    isSelected: false
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 0)
                )

                // Flight list
                ScrollView {
                    if store.trackedFlights.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.trackedFlights) { flight in
                                TrackedFlightCard(
                                    flight: flight,
                                    onTap: {
                                        selectedFlight = flight
                                        showFlightDetail = true
                                    },
                                    onRemove: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            store.removeFlight(flight)
                                        }
                                    },
                                    onTogglePin: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            store.togglePin(for: flight)
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .sheet(isPresented: $showFlightDetail) {
            if let flight = selectedFlight {
                FlightView(
                    flightNumber: flight.flightNumber,
                    originCode: flight.originCode,
                    destinationCode: flight.destinationCode
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "airplane.departure")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Tracked Flights")
                    .font(.system(size: 24, weight: .bold))

                Text("Search for a flight and add it to your tracked flights to see it here")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

struct FilterTab: View {
    let title: String
    let count: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))

            Text("\(count)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
    }
}

struct TrackedFlightCard: View {
    let flight: TrackedFlight
    let onTap: () -> Void
    let onRemove: () -> Void
    let onTogglePin: () -> Void

    var body: some View {
        Button(action: onTap) {
            GlassEffectContainer {
                VStack(alignment: .leading, spacing: 12) {
                    // Header: Flight number and actions
                    HStack {
                        // Flight number
                        Text(flight.flightNumber)
                            .font(.system(size: 20, weight: .bold))

                        Spacer()

                        // Pin button
                        Button(action: onTogglePin) {
                            Image(systemName: flight.isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 16))
                                .foregroundStyle(flight.isPinned ? Color.accentColor : .secondary)
                        }
                        .buttonStyle(.plain)

                        // Remove button
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    // Route display
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(flight.originCode)
                                .font(.system(size: 24, weight: .semibold))

                            if let city = flight.originCity {
                                Text(city)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(flight.destinationCode)
                                .font(.system(size: 24, weight: .semibold))

                            if let city = flight.destinationCity {
                                Text(city)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Status and progress
                    if let status = flight.status {
                        HStack(spacing: 8) {
                            // Status indicator
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor(for: status))
                                    .frame(width: 8, height: 8)

                                Text(status.capitalized)
                                    .font(.system(size: 14, weight: .medium))
                            }

                            Spacer()

                            // Progress
                            if let progress = flight.progress, status == "active" {
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Times
                    if let departure = flight.scheduledDeparture,
                       let arrival = flight.scheduledArrival {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Departure")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)

                                Text(departure, style: .time)
                                    .font(.system(size: 14, weight: .medium))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Arrival")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)

                                Text(arrival, style: .time)
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                    }

                    // Airline name
                    if let airlineName = flight.airlineName {
                        Text(airlineName)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "active":
            return .green
        case "scheduled":
            return .blue
        case "landed":
            return .gray
        case "cancelled":
            return .red
        default:
            return .secondary
        }
    }
}

#Preview {
    TrackedFlightsView()
}
