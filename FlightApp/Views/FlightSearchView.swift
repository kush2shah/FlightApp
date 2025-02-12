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
                    
                    // Recent Searches
                    if !recentSearchStore.recentSearches.isEmpty {
                        recentSearchesSection
                    }
                    
                    // Popular Routes
                    popularRoutesSection
                }
                .padding()
            }
            .navigationTitle("Track Flight")
            .sheet(item: $selectedFlightNumber) { identifiableFlightNumber in
                FlightView(flightNumber: identifiableFlightNumber.value)
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Enter flight number", text: $searchText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .onSubmit(searchFlight)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Searches")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentSearchStore.recentSearches) { search in
                        Button(action: {
                            selectRecentSearch(search)
                        }) {
                            Text(search.route)
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
        
        selectedFlightNumber = IdentifiableString(value: searchText)
        addToRecentSearches()
        isSearchFocused = false
        searchText = "" // Clear search text after submission
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
