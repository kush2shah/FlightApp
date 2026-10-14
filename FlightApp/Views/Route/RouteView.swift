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
    @State private var selectedFlight: IdentifiableString?

    /// Flights shown before "Showing first N flights"
    private let visibleFlightLimit = 10

    var body: some View {
        NavigationView {
            ZStack {
                // Liquid glass background layer
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        if viewModel.isLoading {
                            RouteStatusView(
                                systemImage: "airplane",
                                tint: .blue,
                                title: "Loading Route",
                                message: "Fetching route information...",
                                pulsing: true
                            ) {
                                ProgressView().tint(.blue)
                            }
                            .padding(.top, 100)
                        } else if let error = viewModel.error {
                            RouteStatusView(
                                systemImage: "exclamationmark.triangle.fill",
                                tint: .orange,
                                title: "Error Loading Route",
                                message: error
                            )
                            .padding(.top, 100)
                        } else {
                            routeContentView
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("\(origin) → \(destination)")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedFlight) { flight in
                FlightView(flightNumber: flight.value, faFlightId: flight.faFlightId, skipFlightSelection: true)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
            }
        }
        .task {
            await viewModel.loadRouteData(origin: origin, destination: destination)
        }
    }

    private var routeContentView: some View {
        VStack(spacing: 0) {
            // Great circle is calculated independently, so the map doesn't need IFR route data
            if viewModel.hasRouteAirports {
                RouteMapSection(
                    origin: viewModel.originAirport,
                    destination: viewModel.destinationAirport,
                    route: viewModel.primaryRoute
                )
                .frame(height: 400)
            }

            if viewModel.isEmpty {
                RouteStatusView(
                    systemImage: "airplane.departure",
                    tint: .blue,
                    title: "No Flights Found",
                    message: "There are no scheduled flights on this route today. Try searching for a different date or route."
                )
                .padding(.vertical, 80)
            } else {
                VStack(spacing: 32) {
                    if !viewModel.currentFlights.isEmpty {
                        currentFlightsSection
                    }

                    if !viewModel.awards.isEmpty {
                        awardAvailabilitySection

                        InsightCard(
                            type: .awardAnalysis,
                            context: viewModel.awardInsightContext,
                            airlineColors: viewModel.airlineColors
                        )
                        .padding(.horizontal, 24)
                    }

                    if viewModel.hasRouteAirports {
                        InsightCard(
                            type: .routeContext,
                            context: viewModel.routeInsightContext,
                            airlineColors: viewModel.airlineColors
                        )
                        .padding(.horizontal, 24)
                    }

                    if viewModel.showsCashFares {
                        cashPricesSection
                    }
                }
                .padding(.vertical, 32)
            }
        }
    }

    // MARK: - Flights

    private var currentFlightsSection: some View {
        let flightCount = viewModel.currentFlights.count

        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                sectionTitle("Explore Flights")
                Spacer()
                if flightCount > visibleFlightLimit {
                    Text("\(flightCount) total")
                        .font(.sfRounded(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(viewModel.sortedFlights.prefix(visibleFlightLimit)) { flight in
                    Button {
                        selectedFlight = IdentifiableString(value: flight.ident, faFlightId: flight.faFlightId)
                    } label: {
                        FlightRowCard(flight: flight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)

            if flightCount > visibleFlightLimit {
                Text("Showing first \(visibleFlightLimit) flights")
                    .font(.sfRounded(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Awards

    private var awardAvailabilitySection: some View {
        let cabins = viewModel.cabinsWithAwards

        return VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Awards")
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(Array(cabins.enumerated()), id: \.element) { index, cabin in
                    CabinAwardRow(cabin: cabin, awards: viewModel.awards)

                    if index < cabins.count - 1 {
                        Divider()
                    }
                }
            }
            .background(glassCard)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Cash Prices

    private var cashPricesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Cash Fares")
                .padding(.horizontal, 24)

            if viewModel.isLoadingCashPrices {
                VStack(spacing: 16) {
                    Image(systemName: "airplane")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .symbolEffect(.pulse, options: .repeating)

                    Text("Loading fares in cash...")
                        .font(.sfRounded(size: 15))
                        .foregroundColor(.secondary)

                    ProgressView(value: viewModel.cashPriceLoadingProgress, total: Double(viewModel.cashPriceLoadingTotal))
                        .tint(.blue)
                        .frame(maxWidth: 200)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(glassCard)
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if let bestOffer = viewModel.cashOffers.first {
                // BLUF - best price only
                BestCashPriceRow(offer: bestOffer)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if viewModel.cashPriceError != nil {
                Text("Prices unavailable")
                    .font(.sfRounded(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoadingCashPrices)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.sfRounded(size: 28, weight: .bold))
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.clear)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    RouteView(origin: "JFK", destination: "LHR")
}
