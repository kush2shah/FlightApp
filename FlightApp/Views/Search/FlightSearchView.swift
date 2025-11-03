//
//  FlightSearchView.swift
//  FlightApp
//
//  Created by Kush Shah on 10/12/25.
//

import SwiftUI

struct FlightSearchView: View {
    @State private var selectedFlightNumber: IdentifiableString?
    @State private var selectedRoute: RouteIdentifier?
    @State private var availableFlights: [AeroFlight] = []
    @State private var showFlightSelectionSheet = false
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @State private var showErrorAlert = false
    @State private var lastSearchedFlightNumber: String = ""
    @State private var isSearchExpanded = false
    @State private var showTrackedFlights = false

    @StateObject private var recentSearchStore = RecentSearchStore()
    @State private var refreshTrigger = 0
    private let haptics = HapticManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Track a flight")
                                .font(.sfRounded(size: 34, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Real-time flight tracking worldwide")
                                .font(.sfRounded(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                        // Recent flights section
                        if !recentSearchStore.recentSearches.isEmpty {
                            recentFlightsSection
                                .padding(.bottom, 32)
                        }

                        // Discover section
                        discoverSection
                            .padding(.bottom, 100) // Space for bottom search bar
                    }
                    .padding(.horizontal, 20)
                }

                // Unified search bar (liquid glass)
                UnifiedSearchBar(
                    isActive: $isSearchExpanded,
                    onFlightSearch: { flightNumber, date in
                        haptics.searchSubmitted()
                        searchByFlightNumber(flightNumber, date: date)
                    },
                    onRouteSearch: { origin, destination in
                        haptics.searchSubmitted()
                        selectedRoute = RouteIdentifier(origin: origin.displayCode, destination: destination.displayCode)
                    }
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SettingsButton()
                }

                if FeatureFlags.shared.canUseTrackedFlights {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showTrackedFlights = true
                            haptics.impact(.light)
                        }) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.yellow, .white.opacity(0.3))
                                .symbolRenderingMode(.palette)
                        }
                    }
                }
            }
            .sheet(isPresented: $showFlightSelectionSheet) {
                FlightSelectionSheet(
                    flights: availableFlights,
                    isSearching: isSearching,
                    onSelect: { selectedFlight in
                        selectedFlightNumber = IdentifiableString(value: selectedFlight.ident, faFlightId: selectedFlight.faFlightId)

                        // Fetch airline name and add to recent searches
                        Task {
                            var airlineName: String? = nil
                            if let airlineCode = selectedFlight.operatorIata ?? selectedFlight.operatorIcao {
                                do {
                                    let airlineProfile = try await AirlineService.shared.getAirlineInfo(code: airlineCode)
                                    airlineName = airlineProfile.name
                                } catch {
                                    print("⚠️ Failed to fetch airline name: \(error)")
                                }
                            }

                            // Get the timestamp when this data was actually fetched from the API
                            let cacheKey = AeroAPICacheService.flightInfoKey(flightNumber: selectedFlight.ident, startDate: nil)
                            let cacheTimestamp = AeroAPICacheService.shared.getTimestamp(cacheKey)

                            // If no cache timestamp exists, data was just fetched (use current time)
                            let lastFetchedAt = cacheTimestamp ?? Date()

                            let flightData = RecentFlightData.from(flight: selectedFlight, airlineName: airlineName, lastFetchedAt: lastFetchedAt)
                            print("🔵 [FlightSelectionSheet] Created flight data: \(flightData.flightNumber)")
                            print("   Cache key: \(cacheKey)")
                            print("   Cache timestamp: \(cacheTimestamp?.description ?? "nil")")
                            print("   Using lastFetchedAt: \(lastFetchedAt.description)")
                            print("   Age: \(Date().timeIntervalSince(lastFetchedAt))s ago")
                            await MainActor.run {
                                addToRecentSearches(flightData: flightData)
                                refreshTrigger += 1
                            }
                        }
                    },
                    onDateChange: { newDate in
                        searchByFlightNumber(lastSearchedFlightNumber, date: newDate)
                    }
                )
                .presentationDetents(isSearching || availableFlights.isEmpty ? [.medium] : [.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .onAppear {
                    haptics.sheetOpened()
                }
                .onDisappear {
                    haptics.sheetClosed()
                }
            }
            .sheet(item: $selectedFlightNumber) { identifiableFlightNumber in
                FlightView(flightNumber: identifiableFlightNumber.value, faFlightId: identifiableFlightNumber.faFlightId, skipFlightSelection: true)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                    .onAppear {
                        haptics.sheetOpened()
                    }
                    .onDisappear {
                        haptics.sheetClosed()
                        // Update recent search with fresh flight data when view closes
                        updateRecentSearchFromFlightView(flightNumber: identifiableFlightNumber.value)
                        // Trigger refresh of all flight cards
                        refreshTrigger += 1
                    }
            }
            .sheet(item: $selectedRoute) { route in
                RouteView(origin: route.origin, destination: route.destination)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                    .onAppear {
                        haptics.sheetOpened()
                    }
                    .onDisappear {
                        haptics.sheetClosed()
                    }
            }
            .alert("Search Error", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(searchError ?? "An unknown error occurred")
            })
            .fullScreenCover(isPresented: $showTrackedFlights) {
                NavigationStack {
                    TrackedFlightsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showTrackedFlights = false
                                    haptics.impact(.light)
                                }
                            }
                        }
                }
            }
        }
    }


    // MARK: - Recent Flights Section

    private var recentFlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Flights")
                    .font(.sfRounded(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }

            ForEach(Array(recentSearchStore.recentSearches.prefix(3).enumerated()), id: \.element.id) { index, search in
                RichFlightCard(search: search, refreshTrigger: refreshTrigger)
                    .onAppear {
                        haptics.cardAppeared(delay: Double(index) * 0.05)
                    }
                    .onTapGesture {
                        haptics.cardTapped()
                        selectRecentSearch(search)
                    }
                    .contextMenu {
                        Button {
                            forceRefreshFlight(search.route)
                        } label: {
                            Label("Refresh Flight Data", systemImage: "arrow.clockwise")
                        }

                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                haptics.cardDeleted()
                                recentSearchStore.removeSearch(search)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Discover Section

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Discover")
                    .font(.sfRounded(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(PopularRouteStore.routes.prefix(8)) { route in
                        DiscoverRouteCard(route: route)
                            .onTapGesture {
                                haptics.cardTapped()
                                selectRoute(route)
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, -20) // Counteract parent padding
    }

    // MARK: - Helper Functions

    private func searchByFlightNumber(_ flightNumber: String, date: Date? = nil) {
        lastSearchedFlightNumber = flightNumber

        // Show sheet immediately with loading state
        showFlightSelectionSheet = true
        isSearching = true
        availableFlights = []

        Task {
            do {
                let flights = try await AeroAPIService.shared.getFlightInfo(flightNumber, startDate: date)

                await MainActor.run {
                    availableFlights = flights

                    if !flights.isEmpty {
                        haptics.notificationOccurred(.success)
                    }

                    isSearching = false
                }
            } catch let error as AeroAPIError {
                await MainActor.run {
                    searchError = error.localizedDescription
                    showErrorAlert = true
                    showFlightSelectionSheet = false
                    isSearching = false
                    haptics.notificationOccurred(.error)
                }
                print("Error searching flight: \(error)")
            } catch {
                await MainActor.run {
                    searchError = "Search failed: \(error.localizedDescription)"
                    showErrorAlert = true
                    isSearching = false
                    haptics.notificationOccurred(.error)
                }
                print("Error searching flight: \(error)")
            }
        }
    }

    private func selectRoute(_ route: PopularRoute) {
        selectedFlightNumber = IdentifiableString(value: route.flightNumber, faFlightId: nil)
        recentSearchStore.addSearch(route.flightNumber, type: .flightNumber)
    }

    private func selectRecentSearch(_ search: RecentSearch) {
        selectedFlightNumber = IdentifiableString(value: search.route, faFlightId: nil)
    }

    private func addToRecentSearches(flightData: RecentFlightData) {
        guard let flightNumber = selectedFlightNumber?.value else { return }
        recentSearchStore.addSearch(flightNumber, type: .flightNumber, flightData: flightData)
    }

    private func updateRecentSearchFromFlightView(flightNumber: String) {
        // Fetch fresh flight data and update the recent search
        Task {
            do {
                let flights = try await AeroAPIService.shared.getFlightInfo(flightNumber)
                if let firstFlight = flights.first {
                    // Fetch airline name
                    var airlineName: String? = nil
                    if let airlineCode = firstFlight.operatorIata ?? firstFlight.operatorIcao {
                        do {
                            let airlineProfile = try await AirlineService.shared.getAirlineInfo(code: airlineCode)
                            airlineName = airlineProfile.name
                        } catch {
                            print("⚠️ Failed to fetch airline name: \(error)")
                        }
                    }

                    // Get the timestamp when this data was actually fetched from the API
                    let cacheKey = AeroAPICacheService.flightInfoKey(flightNumber: flightNumber, startDate: nil)
                    let cacheTimestamp = AeroAPICacheService.shared.getTimestamp(cacheKey)

                    // If no cache timestamp exists, data was just fetched (use current time)
                    let lastFetchedAt = cacheTimestamp ?? Date()

                    let flightData = RecentFlightData.from(flight: firstFlight, airlineName: airlineName, lastFetchedAt: lastFetchedAt)
                    await MainActor.run {
                        recentSearchStore.addSearch(flightNumber, type: .flightNumber, flightData: flightData)
                        refreshTrigger += 1
                    }
                }
            } catch {
                print("Failed to update recent search with flight data: \(error)")
            }
        }
    }

    private func forceRefreshFlight(_ flightNumber: String) {
        // Clear cache for this flight to force fresh fetch
        let cacheKey = AeroAPICacheService.flightInfoKey(flightNumber: flightNumber, startDate: nil)
        AeroAPICacheService.shared.remove(cacheKey)

        // Fetch fresh data
        updateRecentSearchFromFlightView(flightNumber: flightNumber)
        haptics.impact(.medium)
    }
}

// MARK: - Rich Flight Card

private struct RichFlightCard: View {
    let search: RecentSearch
    let refreshTrigger: Int  // Used to force refresh when parent updates

    private var brandColors: AirlineBrandColors? {
        guard let data = search.flightData else { return nil }
        return AirlineColorService.shared.getBrandColors(for: data.airlineIATA)
    }

    var body: some View {
        if let data = search.flightData {
            // Rich card with full flight data
            VStack(alignment: .leading, spacing: 16) {
                // Header with airline logo and status
                HStack {
                    AirlineLogoView(iataCode: data.airlineIATA, size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.flightNumber)
                            .font(.sfRounded(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        if let airlineName = data.airlineName {
                            Text(airlineName)
                                .font(.sfRounded(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Status badge
                    statusBadge(status: data.status)
                }

                // Route
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.originCode)
                            .font(.sfRounded(size: 24, weight: .semibold))
                        if let city = data.originCity {
                            Text(city)
                                .font(.sfRounded(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "airplane")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(data.destinationCode)
                            .font(.sfRounded(size: 24, weight: .semibold))
                        if let city = data.destinationCity {
                            Text(city)
                                .font(.sfRounded(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Times and progress
                if let departure = data.scheduledDeparture, let arrival = data.scheduledArrival {
                    HStack {
                        Text(departure.formatted(date: .omitted, time: .shortened))
                            .font(.sfRounded(size: 15, weight: .medium))
                        Spacer()
                        Text(arrival.formatted(date: .omitted, time: .shortened))
                            .font(.sfRounded(size: 15, weight: .medium))
                    }
                    .foregroundColor(.primary)

                    // Progress bar
                    if let progress = data.progress {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.secondarySystemFill))
                                    .frame(height: 6)

                                // Progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }

                // Last updated
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text("Updated \(lastUpdatedString)")
                        .font(.sfRounded(size: 12))
                }
                .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(20)
            .brandedGlassEffect(colors: brandColors, cornerRadius: 20, intensity: 0.18)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .id("\(search.id)-\(refreshTrigger)")  // Force refresh when trigger changes
        } else {
            // Fallback for searches without flight data
            SimpleFlightCard(search: search, refreshTrigger: refreshTrigger)
        }
    }

    private var lastUpdatedString: String {
        guard let data = search.flightData else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: data.lastUpdated, relativeTo: Date())
    }

    private func statusBadge(status: String?) -> some View {
        let (text, color) = statusInfo(status)
        return HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.sfRounded(size: 13, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }

    private func statusInfo(_ status: String?) -> (String, Color) {
        guard let status = status?.lowercased() else {
            return ("Unknown", .gray)
        }

        // Check for cancelled
        if status.contains("cancel") {
            return ("Cancelled", .red)
        }

        // Check for arrived/landed
        if status.contains("arrived") || status.contains("landed") || status.contains("gate arrival") {
            return ("Arrived", .blue)
        }

        // Check for en route/active/in flight
        if status.contains("active") || status.contains("enroute") || status.contains("en route") || status.contains("airborne") {
            return ("En Route", .green)
        }

        // Check for scheduled
        if status.contains("scheduled") {
            return ("Scheduled", .orange)
        }

        // Check for filed (pre-departure)
        if status.contains("filed") {
            return ("Filed", .purple)
        }

        // Check for departed (just took off)
        if status.contains("departed") || status.contains("gate departure") {
            return ("Departed", .green)
        }

        // Check for delayed
        if status.contains("delayed") {
            return ("Delayed", .orange)
        }

        // Check for diverted
        if status.contains("diverted") {
            return ("Diverted", .red)
        }

        // Default for unrecognized statuses
        return ("Unknown", .gray)
    }
}

// MARK: - Simple Flight Card (Fallback)

private struct SimpleFlightCard: View {
    let search: RecentSearch
    let refreshTrigger: Int  // Used to force refresh when parent updates

    var body: some View {
        let info = search.displayInfo

        HStack(spacing: 16) {
            Image(systemName: info.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(info.title)
                    .font(.sfRounded(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Searched \(relativeTimeString)")
                    .font(.sfRounded(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .id("\(search.id)-\(refreshTrigger)")  // Force refresh when trigger changes
    }

    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: search.timestamp, relativeTo: Date())
    }
}

// MARK: - Discover Route Card

private struct DiscoverRouteCard: View {
    let route: PopularRoute

    var body: some View {
        VStack(spacing: 12) {
            // Airline logo
            AirlineLogoView(iataCode: extractIATA(from: route.flightNumber), size: 56)

            // Flight number
            Text(route.flightNumber)
                .font(.sfRounded(size: 16, weight: .bold))
                .foregroundColor(.primary)

            // Route
            HStack(spacing: 6) {
                Text(route.originCode)
                    .font(.sfRounded(size: 13, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                Text(route.destinationCode)
                    .font(.sfRounded(size: 13, weight: .medium))
            }
            .foregroundColor(.secondary)
        }
        .frame(width: 130)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func extractIATA(from flightNumber: String) -> String {
        // Extract airline code from flight number (e.g., "AA1" -> "AA")
        let letters = flightNumber.prefix(while: { $0.isLetter })
        return String(letters)
    }
}

// MARK: - Helper Types

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
    let faFlightId: String?
}

struct RouteIdentifier: Identifiable {
    let id = UUID()
    let origin: String
    let destination: String
}

#Preview {
    FlightSearchView()
}
