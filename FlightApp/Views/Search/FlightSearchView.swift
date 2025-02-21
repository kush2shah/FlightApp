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
                VStack(spacing: 20) {
                    // Search Bar
                    searchBarSection
                    
                    if isSearching {
                        ProgressView("Searching...")
                            .padding()
                    } else {
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
            
            TextField("Enter flight number", text: $searchText)
                .font(.sfRounded(size: 17))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .onSubmit(searchFlight)
                .disabled(isSearching)
            
            if isSearching {
                ProgressView()
                    .padding(.leading, 4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Searches")
                .font(.sfRounded(size: 17, weight: .semibold))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentSearchStore.recentSearches) { search in
                        Button(action: {
                            selectRecentSearch(search)
                        }) {
                            Text(search.route)
                                .font(.sfRounded(size: 15))
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    private var popularRoutesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Popular Routes")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(searchResults) { route in
                    Button(action: {
                        selectRoute(route)
                    }) {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Text(route.originFlag)
                                Text(route.originCode)
                                    .font(.caption)
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)
                                
                                Text(route.destinationFlag)
                                Text(route.destinationCode)
                                    .font(.caption)
                            }
                            
                            Text(route.flightNumber)
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                    }
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
