//
//  FlightSearchView_LiquidGlass.swift
//  FlightApp
//
//  Created by Kush Shah on 10/11/25.
//

import SwiftUI

struct FlightSearchView_LiquidGlass: View {
    @State private var searchText = ""
    @State private var selectedFlightNumber: IdentifiableString?
    @State private var selectedRoute: RouteIdentifier?
    @State private var availableFlights: [AeroFlight] = []
    @State private var showFlightSelectionSheet = false
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @State private var showErrorAlert = false
    @State private var showSettings = false
    @State private var lastSearchedFlightNumber: String = ""
    @FocusState private var isSearchFocused: Bool
    @Namespace private var namespace

    @StateObject private var recentSearchStore = RecentSearchStore()
    private let haptics = HapticManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background gradient
                backgroundGradient

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GlassConstants.sectionSpacing) {
                        Spacer()
                            .frame(height: 20)

                        // Hero search section
                        heroSearchSection

                        // Recent searches - prominent with glass cards
                        if !recentSearchStore.recentSearches.isEmpty {
                            recentSearchesSection
                        }

                        // Popular routes
                        if recentSearchStore.recentSearches.isEmpty {
                            // Show larger popular routes as onboarding
                            featuredPopularRoutesSection
                        } else {
                            // Compact popular routes below recents
                            compactPopularRoutesSection
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Track Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        haptics.impact(.medium)
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showFlightSelectionSheet) {
                FlightSelectionSheet(
                    flights: availableFlights,
                    onSelect: { selectedFlight in
                        selectedFlightNumber = IdentifiableString(value: selectedFlight.ident, faFlightId: selectedFlight.faFlightId)
                        addToRecentSearches()
                        isSearchFocused = false
                    },
                    onDateChange: { newDate in
                        searchByFlightNumber(lastSearchedFlightNumber, date: newDate)
                    }
                )
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
            .sheet(item: $selectedFlightNumber) { identifiableFlightNumber in
                FlightView(flightNumber: identifiableFlightNumber.value, faFlightId: identifiableFlightNumber.faFlightId, skipFlightSelection: true)
                    .presentationDragIndicator(.visible)
                    .onAppear {
                        haptics.sheetOpened()
                    }
                    .onDisappear {
                        haptics.sheetClosed()
                    }
            }
            .sheet(item: $selectedRoute) { route in
                RouteView(origin: route.origin, destination: route.destination)
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
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.15),
                Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.10),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Hero Search Section

    private var heroSearchSection: some View {
        VStack(spacing: 16) {
            Text("Track Any Flight")
                .font(.sfRounded(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Enter flight number or route")
                .font(.sfRounded(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Liquid glass search bar
            liquidGlassSearchBar
        }
    }

    private var liquidGlassSearchBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.secondary)

            TextField("AA1 or JFK LHR...", text: $searchText)
                .font(.sfRounded(size: 20))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .onSubmit(searchFlight)
                .disabled(isSearching)

            if isSearching {
                ProgressView()
                    .scaleEffect(1.2)
            } else if !searchText.isEmpty {
                Button(action: {
                    haptics.searchCleared()
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .glassEffect(.regular, in: .rect(cornerRadius: GlassConstants.searchBarCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GlassConstants.searchBarCornerRadius)
                .stroke(isSearchFocused ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSearchFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchFocused)
        .onChange(of: isSearchFocused) { _, isFocused in
            if isFocused {
                haptics.searchBarFocused()
            }
        }
    }

    // MARK: - Recent Searches Section

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent")
                    .font(.sfRounded(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 4)

            GlassEffectContainer(spacing: GlassConstants.cardSpacing) {
                ForEach(Array(recentSearchStore.recentSearches.prefix(4).enumerated()), id: \.element.id) { index, search in
                    RecentSearchCard(search: search, namespace: namespace)
                        .glassEffectID(search.id.uuidString, in: namespace)
                        .onAppear {
                            haptics.cardAppeared(delay: Double(index) * 0.05)
                        }
                        .onTapGesture {
                            haptics.cardTapped()
                            selectRecentSearch(search)
                        }
                        .contextMenu {
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
    }

    // MARK: - Popular Routes Sections

    private var featuredPopularRoutesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Routes")
                    .font(.sfRounded(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 16
            ) {
                ForEach(PopularRouteStore.routes.prefix(6)) { route in
                    PopularRouteCard(route: route)
                        .glassEffect(.regular, in: .rect(cornerRadius: GlassConstants.cardCornerRadius))
                        .onTapGesture {
                            haptics.cardTapped()
                            selectRoute(route)
                        }
                }
            }
        }
    }

    private var compactPopularRoutesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular")
                    .font(.sfRounded(size: 20, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PopularRouteStore.routes.prefix(8)) { route in
                        CompactRouteCard(route: route)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                            .onTapGesture {
                                haptics.cardTapped()
                                selectRoute(route)
                            }
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func searchFlight() {
        guard !searchText.isEmpty else { return }

        let searchType = SearchInputParser.shared.parse(searchText)
        isSearching = true

        switch searchType {
        case .flightNumber(let flightNumber):
            haptics.searchSubmitted()
            searchByFlightNumber(flightNumber)

        case .route(let origin, let destination):
            haptics.searchSubmitted()
            selectedRoute = RouteIdentifier(origin: origin, destination: destination)
            searchText = ""
            isSearching = false

        case .invalid:
            Task {
                await MainActor.run {
                    searchError = "Invalid search. Try a flight number (e.g., AA1) or route (e.g., JFK LHR)"
                    showErrorAlert = true
                    isSearching = false
                    haptics.notificationOccurred(.error)
                }
            }
        }

        isSearchFocused = false
    }

    private func searchByFlightNumber(_ flightNumber: String, date: Date? = nil) {
        lastSearchedFlightNumber = flightNumber

        Task {
            do {
                let flights = try await AeroAPIService.shared.getFlightInfo(flightNumber, startDate: date)

                await MainActor.run {
                    availableFlights = flights

                    if !flights.isEmpty {
                        showFlightSelectionSheet = true
                        haptics.notificationOccurred(.success)
                    }

                    searchText = ""
                    isSearching = false
                }
            } catch let error as AeroAPIError {
                await MainActor.run {
                    searchError = error.localizedDescription
                    showErrorAlert = true
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
        isSearchFocused = false
    }

    private func selectRecentSearch(_ search: RecentSearch) {
        selectedFlightNumber = IdentifiableString(value: search.route, faFlightId: nil)
        isSearchFocused = false
    }

    private func addToRecentSearches() {
        guard let flightNumber = selectedFlightNumber?.value else { return }
        recentSearchStore.addSearch(flightNumber, type: .flightNumber)
    }
}

// MARK: - Recent Search Card

private struct RecentSearchCard: View {
    let search: RecentSearch
    let namespace: Namespace.ID

    var body: some View {
        let info = search.displayInfo

        HStack(spacing: 16) {
            // Icon
            Image(systemName: info.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(info.title)
                    .font(.sfRounded(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                if let subtitle = info.subtitle {
                    Text(subtitle)
                        .font(.sfRounded(size: 13))
                        .foregroundColor(.secondary)
                }

                Text(search.relativeTimeString)
                    .font(.sfRounded(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .glassEffect(.regular, in: .rect(cornerRadius: GlassConstants.cardCornerRadius))
    }
}

// MARK: - Popular Route Card

private struct PopularRouteCard: View {
    let route: PopularRoute

    var body: some View {
        VStack(spacing: 12) {
            // Route
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    Text(route.originFlag)
                        .font(.title2)
                    Text(route.originCode)
                        .font(.sfRounded(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)

                VStack(spacing: 4) {
                    Text(route.destinationFlag)
                        .font(.title2)
                    Text(route.destinationCode)
                        .font(.sfRounded(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            // Flight number
            Text(route.flightNumber)
                .font(.sfRounded(size: 16, weight: .bold))
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Compact Route Card

private struct CompactRouteCard: View {
    let route: PopularRoute

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(route.originFlag)
                Text(route.destinationFlag)
            }
            .font(.title3)

            Text(route.flightNumber)
                .font(.sfRounded(size: 14, weight: .bold))
                .foregroundColor(.blue)

            Text("\(route.originCode)-\(route.destinationCode)")
                .font(.sfRounded(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    FlightSearchView_LiquidGlass()
}
