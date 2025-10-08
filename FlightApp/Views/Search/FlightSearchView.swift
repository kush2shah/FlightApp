//
//  FlightSearchView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/10/25.
//

import SwiftUI

struct FlightSearchView: View {
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

    @StateObject private var recentSearchStore = RecentSearchStore()
    
    
    private var searchResults: [PopularRoute] {
        guard !searchText.isEmpty else { return PopularRouteStore.routes }
        
        return PopularRouteStore.routes.filter { route in
            route.flightNumber.localizedCaseInsensitiveContains(searchText) ||
            route.originCode.localizedCaseInsensitiveContains(searchText) ||
            route.destinationCode.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    
                    // Hero Search Bar - Centered
                    VStack(spacing: 32) {
                        heroSearchBarSection
                        
                        if isSearching {
                            ProgressView("Searching...")
                                .font(.sfRounded(size: 16))
                                .foregroundColor(.secondary)
                        } else {
                            // Recent Searches (if any)
                            if !recentSearchStore.recentSearches.isEmpty {
                                recentSearchesSection
                            }
                            
                            // Search hints
                            searchHintsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    Spacer() // Extra spacer to push content up slightly
                }
            }
            .navigationTitle("Track Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(PopularRouteStore.routes.prefix(6)) { route in
                            Button(action: {
                                selectRoute(route)
                            }) {
                                Label(route.routeDisplayName, systemImage: "airplane")
                            }
                        }

                        Divider()

                        Button(action: {
                            // Could expand to show all routes in future
                        }) {
                            Label("Browse All Routes", systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .sheet(isPresented: $showFlightSelectionSheet) {
                FlightSelectionSheet(
                    flights: availableFlights,
                    onSelect: { selectedFlight in
                        selectedFlightNumber = IdentifiableString(value: selectedFlight.ident)
                        addToRecentSearches()
                        isSearchFocused = false
                    },
                    onDateChange: { newDate in
                        // Re-search with the selected date
                        searchByFlightNumber(lastSearchedFlightNumber, date: newDate)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedFlightNumber) { identifiableFlightNumber in
                FlightView(flightNumber: identifiableFlightNumber.value, skipFlightSelection: true)
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedRoute) { route in
                RouteView(origin: route.origin, destination: route.destination)
            }
            .alert("Search Error", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(searchError ?? "An unknown error occurred")
            })
        }
    }
    
    private var heroSearchBarSection: some View {
        VStack(spacing: 16) {
            // App title/tagline
            Text("Track Any Flight")
                .font(.sfRounded(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Enter flight number or route")
                .font(.sfRounded(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Large hero search bar
            heroSearchField
        }
    }
    
    private var heroSearchField: some View {
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
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSearchFocused ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSearchFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
    
    private var searchHintsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                searchHintButton("AA1", icon: "airplane")
                searchHintButton("JFK LHR", icon: "arrow.right")
            }

            Text("Try a flight number or route")
                .font(.sfRounded(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private func searchHintButton(_ text: String, icon: String) -> some View {
        Button(action: {
            searchText = text
            searchFlight()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(text)
                    .font(.sfRounded(size: 15, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
        }
    }
    
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 18, weight: .medium))
            
            TextField("Enter flight number", text: $searchText)
                .font(.sfRounded(size: 17))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .onSubmit(searchFlight)
                .disabled(isSearching)
            
            if isSearching {
                ProgressView()
                    .scaleEffect(0.9)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private var featuredFlightSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured Flight")
                    .font(.sfRounded(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("Live")
                    .font(.sfRounded(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            
            Button(action: {
                selectRoute(PopularRouteStore.featuredRoute)
            }) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(PopularRouteStore.featuredRoute.originFlag)
                                .font(.title2)
                            Text(PopularRouteStore.featuredRoute.originCode)
                                .font(.sfRounded(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        Text(PopularRouteStore.featuredRoute.origin)
                            .font(.sfRounded(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: "airplane")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text(PopularRouteStore.featuredRoute.flightNumber)
                            .font(.sfRounded(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack {
                            Text(PopularRouteStore.featuredRoute.destinationCode)
                                .font(.sfRounded(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Text(PopularRouteStore.featuredRoute.destinationFlag)
                                .font(.title2)
                        }
                        Text(PopularRouteStore.featuredRoute.destination)
                            .font(.sfRounded(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var recentSearchesSection: some View {
        VStack(spacing: 12) {
            Text("Recent")
                .font(.sfRounded(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentSearchStore.recentSearches.prefix(4)) { search in
                        Button(action: {
                            selectRecentSearch(search)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text(search.route)
                                    .font(.sfRounded(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
    
    private var popularRoutesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Routes")
                    .font(.sfRounded(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(searchResults.count) routes")
                    .font(.sfRounded(size: 14))
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 16
            ) {
                ForEach(searchResults) { route in
                    Button(action: {
                        selectRoute(route)
                    }) {
                        VStack(spacing: 12) {
                            // Route Header
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(route.originFlag)
                                            .font(.title3)
                                        Text(route.originCode)
                                            .font(.sfRounded(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "airplane")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                    .rotationEffect(.degrees(-45))
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(route.destinationCode)
                                            .font(.sfRounded(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(route.destinationFlag)
                                            .font(.title3)
                                    }
                                }
                            }
                            
                            // Flight Number
                            HStack {
                                Text(route.flightNumber)
                                    .font(.sfRounded(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func searchFlight() {
        guard !searchText.isEmpty else { return }

        // Parse input to determine search type
        let searchType = SearchInputParser.shared.parse(searchText)

        // Set searching state to true
        isSearching = true

        switch searchType {
        case .flightNumber(let flightNumber):
            searchByFlightNumber(flightNumber)

        case .route(let origin, let destination):
            // Navigate to RouteView
            selectedRoute = RouteIdentifier(origin: origin, destination: destination)
            searchText = ""
            isSearching = false

        case .invalid:
            Task {
                await MainActor.run {
                    searchError = "Invalid search. Try a flight number (e.g., AA1) or route (e.g., JFK LHR)"
                    showErrorAlert = true
                    isSearching = false
                }
            }
        }

        isSearchFocused = false
    }

    private func searchByFlightNumber(_ flightNumber: String, date: Date? = nil) {
        // Store the flight number for date-based re-searches
        lastSearchedFlightNumber = flightNumber

        // Use AeroAPIService to fetch flights
        Task {
            do {
                let flights = try await AeroAPIService.shared.getFlightInfo(flightNumber, startDate: date)

                await MainActor.run {
                    availableFlights = flights

                    if flights.count == 1 {
                        // If only one flight, directly select it without showing selection sheet
                        let flight = flights[0]
                        selectedFlightNumber = IdentifiableString(value: flight.ident)
                        recentSearchStore.addSearch(flightNumber)
                    } else if !flights.isEmpty {
                        // If multiple flights, show selection sheet
                        showFlightSelectionSheet = true
                    }

                    // Only clear search text after successful search
                    searchText = ""
                    isSearching = false
                }
            } catch let error as AeroAPIError {
                // Handle AeroAPI specific errors
                await MainActor.run {
                    searchError = error.localizedDescription
                    showErrorAlert = true
                    isSearching = false
                }
                print("Error searching flight: \(error)")
            } catch {
                // Handle generic errors
                await MainActor.run {
                    searchError = "Search failed: \(error.localizedDescription)"
                    showErrorAlert = true
                    isSearching = false
                }
                print("Error searching flight: \(error)")
            }
        }
    }
    
    private func selectRoute(_ route: PopularRoute) {
        selectedFlightNumber = IdentifiableString(value: route.flightNumber)
        addToRecentSearches()
        isSearchFocused = false
    }
    
    private func selectRecentSearch(_ search: RecentSearch) {
        selectedFlightNumber = IdentifiableString(value: search.route)
        addToRecentSearches()
        isSearchFocused = false
    }
    
    private func addToRecentSearches() {
        guard let flightNumber = selectedFlightNumber?.value else { return }
        recentSearchStore.addSearch(flightNumber)
    }
}

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

struct RouteIdentifier: Identifiable {
    let id = UUID()
    let origin: String
    let destination: String
}

#Preview {
    FlightSearchView()
}
