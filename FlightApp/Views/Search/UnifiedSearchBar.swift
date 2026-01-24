//
//  UnifiedSearchBar.swift
//  FlightApp
//
//  Created by Kush Shah on 11/2/25.
//

import SwiftUI
import CoreLocation

/// Unified search bar that intelligently handles both flight numbers and route searches
struct UnifiedSearchBar: View {
    @Binding var isActive: Bool
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .auto
    @State private var airportSearchResults: [Airport] = []
    @State private var selectedOrigin: Airport?
    @State private var selectedDestination: Airport?
    @State private var currentStage: RouteStage = .origin
    @State private var detectedAirlineCode: String?
    @State private var airlineName: String?
    @State private var selectedDate: Date?
    @State private var showDatePicker = false

    @FocusState private var isSearchFocused: Bool

    private let haptics = HapticManager.shared
    private let searchService = AirportSearchService.shared
    private let inputParser = SearchInputParser.shared
    private let flightParser = FlightNumberParser.shared

    // Callbacks
    var onFlightSearch: (String, Date?) -> Void
    var onRouteSearch: (Airport, Airport) -> Void

    enum SearchMode {
        case auto // Automatically detect
        case flight
        case route
    }

    enum RouteStage {
        case origin
        case destination
    }

    var body: some View {
        ZStack {
            // Backdrop
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
                    searchHeader
                    if isActive {
                        searchContent
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
        .onChange(of: searchText) { _, newValue in
            handleSearchTextChange(newValue)
        }
        .onChange(of: isSearchFocused) { _, newValue in
            // Prevent unwanted focus loss
            if isActive && !newValue && selectedOrigin != nil && selectedDestination == nil {
                // We're in route building mode and focus was lost - restore it
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isSearchFocused = true
                }
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: detectIcon())
                .font(.system(size: isActive ? 22 : 20, weight: .medium))
                .foregroundColor(.secondary)

            // Content
            if isActive {
                activeSearchContent
            } else {
                Text("Search flight number or route...")
                    .font(.sfRounded(size: 17))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            if isActive && !searchText.isEmpty {
                Button(action: {
                    haptics.impact(.light)
                    clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
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

    private var activeSearchContent: some View {
        Group {
            if searchMode == .route && selectedOrigin != nil {
                // Route mode: show origin → destination
                HStack(spacing: 12) {
                    selectedAirportChip(selectedOrigin!, isOrigin: true)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)

                    if let destination = selectedDestination {
                        selectedAirportChip(destination, isOrigin: false)
                    } else {
                        TextField("Destination", text: $searchText)
                            .font(.sfRounded(size: 17))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($isSearchFocused)
                            .onSubmit {
                                handleSubmit()
                            }
                    }
                }
            } else {
                // Flight or auto mode
                TextField("AA1 or JFK LHR...", text: $searchText)
                    .font(.sfRounded(size: 20))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                    .onSubmit {
                        handleSubmit()
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

    // MARK: - Search Content

    private var searchContent: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, 20)

            // Mode indicator (if ambiguous)
            if searchMode == .auto && !searchText.isEmpty {
                searchModeHints
            }

            // Results
            if searchMode == .route || (searchMode == .auto && looksLikeRoute()) {
                airportResults
            } else if !searchText.isEmpty && searchMode == .flight {
                flightHints
            } else if searchText.isEmpty && searchMode == .auto {
                // Show airport suggestions when empty
                airportResults
            }
        }
    }

    private var searchModeHints: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Detect what they're typing
                if looksLikeRoute() {
                    modeChip(icon: "arrow.right", text: "Searching routes", color: .blue)
                } else if looksLikeFlightNumber() {
                    modeChip(icon: "airplane", text: "Searching flights", color: .green)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func modeChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.sfRounded(size: 13, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private var airportResults: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                HStack {
                    Text(selectedOrigin != nil ? "Popular from \(selectedOrigin!.displayCode)" : "Airports")
                        .font(.sfRounded(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ForEach(airportSearchResults) { airport in
                    airportRow(airport)
                }
            }
            .padding(.bottom, 16)
        }
        .frame(maxHeight: 320)
    }

    private func airportRow(_ airport: Airport) -> some View {
        Button(action: {
            selectAirport(airport)
        }) {
            HStack(spacing: 12) {
                Text(airport.flagEmoji)
                    .font(.system(size: 24))

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

    private var flightHints: some View {
        VStack(spacing: 16) {
            // Airline branding if detected
            if let airlineCode = detectedAirlineCode {
                HStack(spacing: 12) {
                    // Airline logo
                    AirlineLogoView(iataCode: airlineCode, size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        if let name = airlineName {
                            Text(name)
                                .font(.sfRounded(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        } else {
                            // Show code while loading
                            Text(airlineCode)
                                .font(.sfRounded(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        Text("Flight \(searchText.uppercased())")
                            .font(.sfRounded(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    Spacer()

                    // Airplane icon
                    Image(systemName: "airplane")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(16)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }

            // Date selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Select flight date")
                    .font(.sfRounded(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)

                // Quick date options
                HStack(spacing: 12) {
                    dateQuickButton("Yesterday", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
                    dateQuickButton("Today", date: Date())
                    dateQuickButton("Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                }
                .padding(.horizontal, 20)

                // Custom date picker button
                Button(action: {
                    showDatePicker.toggle()
                    haptics.impact(.light)
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .medium))
                        if let date = selectedDate, !isQuickDate(date) {
                            Text(formatDate(date))
                                .font(.sfRounded(size: 15, weight: .medium))
                        } else {
                            Text("Pick a date")
                                .font(.sfRounded(size: 15, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(showDatePicker ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.1))
                    .foregroundColor(showDatePicker ? .blue : .primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                // Date picker
                if showDatePicker {
                    DatePicker("", selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: {
                            selectedDate = $0
                            showDatePicker = false
                            // Auto-submit when date is selected via date picker
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                handleSubmit()
                            }
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .scale))
                }
            }

            // Search hint
            HStack {
                Text(selectedDate == nil ? "Select a date to search" : "Searching...")
                    .font(.sfRounded(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .padding(.top, 12)
    }

    private var searchHints: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                searchHintButton("AA1", icon: "airplane", color: .green)
                searchHintButton("JFK LHR", icon: "arrow.right", color: .blue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private func searchHintButton(_ text: String, icon: String, color: Color) -> some View {
        Button(action: {
            searchText = text
            handleSubmit()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(text)
                    .font(.sfRounded(size: 15, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }

    private func dateQuickButton(_ label: String, date: Date) -> some View {
        Button(action: {
            selectedDate = date
            showDatePicker = false
            haptics.impact(.light)
            // Auto-submit when date is selected via quick button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                handleSubmit()
            }
        }) {
            Text(label)
                .font(.sfRounded(size: 14, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelectedDate(date) ? Color.blue : Color.secondary.opacity(0.1))
                .foregroundColor(isSelectedDate(date) ? .white : .primary)
                .cornerRadius(10)
        }
    }

    private func isSelectedDate(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(selected, inSameDayAs: date)
    }

    private func isQuickDate(_ date: Date) -> Bool {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        return Calendar.current.isDate(date, inSameDayAs: today) ||
               Calendar.current.isDate(date, inSameDayAs: yesterday) ||
               Calendar.current.isDate(date, inSameDayAs: tomorrow)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Detection Logic

    private func detectIcon() -> String {
        if selectedOrigin != nil || searchMode == .route {
            return "airplane"
        }
        return "magnifyingglass"
    }

    private func looksLikeRoute() -> Bool {
        let parsed = inputParser.parse(searchText)
        if case .route = parsed {
            return true
        }
        // Also consider it a route if it's 3-4 letters (airport code)
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 4 && trimmed.allSatisfy { $0.isLetter }
    }

    private func looksLikeFlightNumber() -> Bool {
        let parsed = inputParser.parse(searchText)
        if case .flightNumber = parsed {
            return true
        }
        return false
    }

    // MARK: - Actions

    private func activateSearch() {
        isActive = true
        isSearchFocused = true
        searchMode = .auto
        updateAirportResults()
        haptics.glassClick()
    }

    private func dismissSearch() {
        isActive = false
        isSearchFocused = false
        clearAll()
        haptics.impact(.light)
    }

    private func handleSearchTextChange(_ text: String) {
        // If we already have an origin selected, we're in route building mode - don't change modes
        if selectedOrigin != nil {
            updateAirportResults()
            return
        }
        
        // Otherwise, auto-detect the search mode
        if looksLikeRoute() {
            searchMode = .route
            updateAirportResults()
            detectedAirlineCode = nil
            airlineName = nil
        } else if looksLikeFlightNumber() {
            searchMode = .flight
            // Extract and fetch airline info
            if let parsed = flightParser.parseFlightNumber(text) {
                detectedAirlineCode = parsed.airlineCode
                fetchAirlineName(for: parsed.airlineCode)
            }
        } else {
            searchMode = .auto
            detectedAirlineCode = nil
            airlineName = nil
            if !text.isEmpty {
                updateAirportResults()
            }
        }
    }

    private func fetchAirlineName(for airlineCode: String) {
        Task {
            do {
                let airlineInfo = try await AirlineService.shared.getAirlineInfo(code: airlineCode)
                await MainActor.run {
                    airlineName = airlineInfo.name
                }
            } catch {
                // Silently fail - airline name is optional
                await MainActor.run {
                    airlineName = nil
                }
            }
        }
    }

    private func updateAirportResults() {
        if let origin = selectedOrigin, currentStage == .destination {
            if searchText.isEmpty {
                airportSearchResults = searchService.getPopularDestinations(from: origin.displayCode, limit: 8)
            } else {
                airportSearchResults = searchService.search(query: searchText, limit: 8)
            }
        } else {
            airportSearchResults = searchService.search(query: searchText, limit: 8)
        }
    }

    private func selectAirport(_ airport: Airport) {
        if selectedOrigin == nil {
            selectedOrigin = airport
            currentStage = .destination
            searchMode = .route
            searchText = ""
            updateAirportResults()
            
            // Delay focus to ensure state changes are processed first
            DispatchQueue.main.async {
                self.isSearchFocused = true
            }
            haptics.glassForming()
        } else {
            selectedDestination = airport
            haptics.glassBreaking()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let origin = self.selectedOrigin {
                    self.onRouteSearch(origin, airport)
                }
                self.dismissSearch()
            }
        }
    }

    private func handleSubmit() {
        let parsed = inputParser.parse(searchText)

        switch parsed {
        case .flightNumber(let flightNumber):
            // For flight numbers, require a date to be selected
            if selectedDate != nil {
                onFlightSearch(flightNumber, selectedDate)
                dismissSearch()
            } else {
                haptics.notificationOccurred(.warning)
            }

        case .route(let origin, let destination):
            // Try to find airports
            if let originAirport = searchService.getAirport(byCode: origin),
               let destAirport = searchService.getAirport(byCode: destination) {
                onRouteSearch(originAirport, destAirport)
                dismissSearch()
            }

        case .invalid:
            // Check if it's a single airport code - select first result if available
            if !searchText.isEmpty && !airportSearchResults.isEmpty {
                selectAirport(airportSearchResults[0])
            } else if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
                // Try direct airport lookup if it looks like a code
                if let airport = searchService.getAirport(byCode: searchText.uppercased()) {
                    selectAirport(airport)
                } else {
                    haptics.notificationOccurred(.error)
                }
            } else {
                haptics.notificationOccurred(.error)
            }
        }
    }

    private func clearSearch() {
        searchText = ""
        searchMode = .auto
    }

    private func clearOrigin() {
        selectedOrigin = nil
        selectedDestination = nil
        currentStage = .origin
        searchText = ""
        searchMode = .auto
        updateAirportResults()
        
        DispatchQueue.main.async {
            self.isSearchFocused = true
        }
        haptics.impact(.light)
    }

    private func clearDestination() {
        selectedDestination = nil
        searchText = ""
        updateAirportResults()
        
        DispatchQueue.main.async {
            self.isSearchFocused = true
        }
        haptics.impact(.light)
    }

    private func clearAll() {
        searchText = ""
        selectedOrigin = nil
        selectedDestination = nil
        currentStage = .origin
        searchMode = .auto
        airportSearchResults = []
        selectedDate = nil
        showDatePicker = false
    }
}
