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
    @State private var availableFlights: [AeroFlight] = []
    @State private var showFlightSelectionSheet = false
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @State private var showErrorAlert = false
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
            ScrollView {
                VStack(spacing: 24) {
                    // Search Bar
                    searchBarSection
                    
                    if isSearching {
                        ProgressView("Searching...")
                            .padding()
                    } else {
                        // Hero Section - Featured Flight
                        featuredFlightSection
                        
                        // Recent Searches
                        if !recentSearchStore.recentSearches.isEmpty {
                            recentSearchesSection
                        }
                        
                        // Popular Routes
                        popularRoutesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Track Flight")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showFlightSelectionSheet) {
                FlightSelectionSheet(
                    flights: availableFlights,
                    onSelect: { selectedFlight in
                        selectedFlightNumber = IdentifiableString(value: selectedFlight.ident)
                        addToRecentSearches()
                        isSearchFocused = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedFlightNumber) { identifiableFlightNumber in
                FlightView(flightNumber: identifiableFlightNumber.value, skipFlightSelection: true)
                    .presentationDragIndicator(.visible)
            }
            .alert("Search Error", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(searchError ?? "An unknown error occurred")
            })
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Searches")
                .font(.sfRounded(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentSearchStore.recentSearches) { search in
                        Button(action: {
                            selectRecentSearch(search)
                        }) {
                            Text(search.route)
                                .font(.sfRounded(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 2)
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
        
        // Store the flight number to search
        let flightToSearch = searchText.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Set searching state to true
        isSearching = true
        
        // Use AeroAPIService to fetch flights
        Task {
            do {
                let flights = try await AeroAPIService.shared.getFlightInfo(flightToSearch)
                
                await MainActor.run {
                    availableFlights = flights
                    
                    if flights.count == 1 {
                        // If only one flight, directly select it without showing selection sheet
                        let flight = flights[0]
                        selectedFlightNumber = IdentifiableString(value: flight.ident)
                        recentSearchStore.addSearch(flightToSearch)
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
        
        isSearchFocused = false
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

#Preview {
    FlightSearchView()
}
