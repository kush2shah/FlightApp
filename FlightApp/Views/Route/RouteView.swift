//
//  RouteView.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import SwiftUI

struct RouteView: View {
    let origin: String
    let destination: String

    @StateObject private var viewModel = RouteViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        routeContentView
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(origin) → \(destination)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadRouteData(origin: origin, destination: destination)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading route information...")
                .font(.sfRounded(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Error Loading Route")
                .font(.sfRounded(size: 20, weight: .semibold))
            Text(error)
                .font(.sfRounded(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private var routeContentView: some View {
        VStack(spacing: 24) {
            // Route stats section
            if !viewModel.ifrRoutes.isEmpty {
                routeStatsSection
            }

            // Current flights section
            if !viewModel.currentFlights.isEmpty {
                currentFlightsSection
            }

            // Award availability section
            if !viewModel.awards.isEmpty {
                awardAvailabilitySection
            } else if viewModel.shouldShowAwards {
                noAwardsView
            }
        }
    }

    private var routeStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route Information")
                .font(.sfRounded(size: 22, weight: .bold))
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(viewModel.ifrRoutes.prefix(3)) { route in
                    RouteStatCard(route: route)
                }
            }
            .padding(.horizontal)
        }
    }

    private var currentFlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flights on This Route")
                .font(.sfRounded(size: 22, weight: .bold))
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(viewModel.currentFlights.prefix(10)) { flight in
                    FlightRowCard(flight: flight)
                }
            }
            .padding(.horizontal)
        }
    }

    private var awardAvailabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Award Availability")
                    .font(.sfRounded(size: 22, weight: .bold))
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(viewModel.awards.prefix(20)) { award in
                    AwardRowCard(award: award)
                }
            }
            .padding(.horizontal)

            if viewModel.awards.count > 20 {
                Text("Showing top 20 results")
                    .font(.sfRounded(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
    }

    private var noAwardsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.slash")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No award availability found")
                .font(.sfRounded(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Route Stat Card

struct RouteStatCard: View {
    let route: IFRRouteInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Route")
                    .font(.sfRounded(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(route.count) flights")
                    .font(.sfRounded(size: 12))
                    .foregroundColor(.secondary)
            }

            Text(route.route)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(2)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Altitude")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                    Text("FL\(route.filedAltitudeMin/100)-\(route.filedAltitudeMax/100)")
                        .font(.sfRounded(size: 14, weight: .medium))
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                    Text(route.routeDistance)
                        .font(.sfRounded(size: 14, weight: .medium))
                }

                Spacer()
            }

            if !route.aircraftTypes.isEmpty {
                HStack {
                    Text("Common aircraft:")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                    Text(route.aircraftTypes.prefix(3).joined(separator: ", "))
                        .font(.sfRounded(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Flight Row Card

struct FlightRowCard: View {
    let flight: AeroFlight

    var body: some View {
        HStack(spacing: 16) {
            // Flight number
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.ident)
                    .font(.sfRounded(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                if let operator_iata = flight.operator_iata {
                    Text(operator_iata)
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Time info
            VStack(alignment: .trailing, spacing: 4) {
                if let scheduledOut = flight.scheduledOut {
                    Text(formatTime(scheduledOut))
                        .font(.sfRounded(size: 14, weight: .medium))
                }
                if flight.isInProgress {
                    Text("In Flight")
                        .font(.sfRounded(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    Text("Scheduled")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, h:mm a"
        return timeFormatter.string(from: date)
    }
}

// MARK: - Award Row Card

struct AwardRowCard: View {
    let award: AwardAvailability

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(award.date))
                    .font(.sfRounded(size: 14, weight: .semibold))
                Text(formatProgram(award.source))
                    .font(.sfRounded(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let cabin = award.bestAvailableCabin() {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(cabin.cost)
                            .font(.sfRounded(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                        Text("pts")
                            .font(.sfRounded(size: 12))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Text(cabin.cabin)
                            .font(.sfRounded(size: 12, weight: .medium))
                        Text("(\(cabin.seats) left)")
                            .font(.sfRounded(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatProgram(_ source: String) -> String {
        source.capitalized.replacingOccurrences(of: "_", with: " ")
    }
}

#Preview {
    RouteView(origin: "JFK", destination: "LHR")
}
