//
//  LiquidRouteSearchBar.swift
//  FlightApp
//
//  Created by Kush Shah on 11/2/25.
//

import SwiftUI
import CoreLocation

/// Liquid glass search bar with morphing states for route selection
struct LiquidRouteSearchBar: View {
    @Binding var isActive: Bool
    @Binding var selectedOrigin: Airport?
    @Binding var selectedDestination: Airport?

    @State private var searchText = ""
    @State private var searchResults: [Airport] = []
    @State private var currentStage: SearchStage = .origin
    @FocusState private var isSearchFocused: Bool

    private let haptics = HapticManager.shared
    private let searchService = AirportSearchService.shared

    // Optional user location for nearby suggestions
    var userLocation: CLLocationCoordinate2D? = nil

    // Callback when route is complete
    var onRouteComplete: (Airport, Airport) -> Void

    enum SearchStage {
        case origin
        case destination
    }

    var body: some View {
        ZStack {
            // Backdrop for expanded state
            if isActive {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissSearch()
                    }
                    .transition(.opacity)
            }

            // Morphing search bar
            VStack {
                if isActive {
                    Spacer()
                        .frame(height: 100)
                }

                if !isActive {
                    Spacer()
                }

                // Main search content
                VStack(spacing: 0) {
                    // Search header
                    searchHeader

                    // Search results / suggestions
                    if isActive {
                        searchSuggestions
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: isActive ? 20 : 25))
                .shadow(
                    color: Color.black.opacity(isActive ? 0.2 : 0.15),
                    radius: isActive ? 30 : 20,
                    x: 0,
                    y: isActive ? 15 : 10
                )
                .padding(.horizontal, 20)
                .padding(.bottom, isActive ? 0 : 20)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedOrigin)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDestination)
        .onChange(of: searchText) { _, newValue in
            updateSearchResults(for: newValue)
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: isActive ? "airplane" : "magnifyingglass")
                .font(.system(size: isActive ? 22 : 20, weight: .medium))
                .foregroundColor(.secondary)

            // Search content
            if isActive {
                routeBuilderContent
            } else {
                Text("Search flight number or route...")
                    .font(.sfRounded(size: 17))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            if isActive {
                searchActions
            }
        }
        .padding(.horizontal, isActive ? 24 : 20)
        .padding(.vertical, isActive ? 20 : 16)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isActive {
                activateSearch()
            }
        }
    }

    // MARK: - Route Builder Content

    private var routeBuilderContent: some View {
        HStack(spacing: 12) {
            // Origin selector
            if let origin = selectedOrigin {
                selectedAirportChip(origin, isOrigin: true)
            } else {
                activeSearchField(placeholder: "Origin (e.g., JFK)")
            }

            // Arrow
            if selectedOrigin != nil {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .transition(.scale.combined(with: .opacity))
            }

            // Destination selector
            if selectedOrigin != nil {
                if let destination = selectedDestination {
                    selectedAirportChip(destination, isOrigin: false)
                } else {
                    activeSearchField(placeholder: "Destination")
                }
            }
        }
    }

    private func selectedAirportChip(_ airport: Airport, isOrigin: Bool) -> some View {
        HStack(spacing: 6) {
            Text(airport.flagEmoji)
                .font(.system(size: 16))

            Text(airport.displayCode)
                .font(.sfRounded(size: 17, weight: .semibold))

            Button(action: {
                if isOrigin {
                    clearOrigin()
                } else {
                    clearDestination()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private func activeSearchField(placeholder: String) -> some View {
        TextField(placeholder, text: $searchText)
            .font(.sfRounded(size: 17))
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .focused($isSearchFocused)
    }

    // MARK: - Search Actions

    private var searchActions: some View {
        HStack(spacing: 12) {
            if !searchText.isEmpty {
                Button(action: {
                    haptics.impact(.light)
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Search Suggestions

    private var searchSuggestions: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    // Context header
                    if !searchText.isEmpty {
                        HStack {
                            Text("Results")
                                .font(.sfRounded(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    } else if selectedOrigin != nil && currentStage == .destination {
                        HStack {
                            Text("Popular from \(selectedOrigin!.displayCode)")
                                .font(.sfRounded(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    } else {
                        HStack {
                            Text(userLocation != nil ? "Nearby & Popular" : "Popular Airports")
                                .font(.sfRounded(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }

                    // Results
                    ForEach(searchResults) { airport in
                        airportResultRow(airport)
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 320)
        }
    }

    private func airportResultRow(_ airport: Airport) -> some View {
        Button(action: {
            selectAirport(airport)
        }) {
            HStack(spacing: 12) {
                // Flag
                Text(airport.flagEmoji)
                    .font(.system(size: 24))

                // Airport info
                VStack(alignment: .leading, spacing: 2) {
                    Text(airport.displayName)
                        .font(.sfRounded(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(airport.name)
                        .font(.sfRounded(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Code badge
                Text(airport.displayCode)
                    .font(.sfRounded(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Actions

    private func activateSearch() {
        isActive = true
        isSearchFocused = true
        currentStage = .origin
        updateSearchResults(for: "")
        haptics.glassClick()
    }

    private func dismissSearch() {
        isActive = false
        isSearchFocused = false
        searchText = ""
        searchResults = []
        selectedOrigin = nil
        selectedDestination = nil
        currentStage = .origin
        haptics.impact(.light)
    }

    private func selectAirport(_ airport: Airport) {
        searchText = ""

        if currentStage == .origin {
            selectedOrigin = airport
            currentStage = .destination
            updateSearchResults(for: "")
            isSearchFocused = true
            haptics.glassForming()
        } else {
            selectedDestination = airport
            haptics.glassBreaking()

            // Complete the route
            if let origin = selectedOrigin {
                // Delay slightly for animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onRouteComplete(origin, airport)
                    dismissSearch()
                }
            }
        }
    }

    private func clearOrigin() {
        selectedOrigin = nil
        selectedDestination = nil
        currentStage = .origin
        searchText = ""
        updateSearchResults(for: "")
        isSearchFocused = true
        haptics.impact(.light)
    }

    private func clearDestination() {
        selectedDestination = nil
        searchText = ""
        updateSearchResults(for: "")
        isSearchFocused = true
        haptics.impact(.light)
    }

    private func updateSearchResults(for query: String) {
        if query.isEmpty {
            // Show contextual suggestions
            if let origin = selectedOrigin, currentStage == .destination {
                // Popular destinations from origin
                searchResults = searchService.getPopularDestinations(from: origin.displayCode, limit: 8)
            } else {
                // Default suggestions (nearby + popular)
                searchResults = searchService.search(query: "", limit: 8, userLocation: userLocation)
            }
        } else {
            // Search with query
            searchResults = searchService.search(query: query, limit: 8, userLocation: userLocation)
        }
    }
}
