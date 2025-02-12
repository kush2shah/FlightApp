//
//  FlightSearchView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/10/25.
//

import SwiftUI

// Make String identifiable for sheet presentation
extension String: Identifiable {
    public var id: String { self }
}

struct FlightSearchView: View {
    @State private var searchText = ""
    @State private var isFlightSheetPresented = false
    @State private var selectedFlight: String?
    @FocusState private var isSearchFocused: Bool
    
    // Simplified data structure for quick testing
    let commonCarriers = [
        "United": ["UA837", "UA60", "UA106"],
        "Singapore": ["SQ12", "SQ31", "SQ11"],
        "American": ["AA100", "AA137", "AA187"]
    ]
    
    private var isValidFlightNumber: Bool {
        // 2-3 characters followed by 1-4 digits
        let pattern = "^[A-Z0-9]{2,3}[0-9]{1,4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: searchText.uppercased())
    }
    
    private func searchFlight() {
        guard isValidFlightNumber else { return }
        
        selectedFlight = searchText
        isFlightSheetPresented = true
        isSearchFocused = false
    }
    
    var body: some View {
        NavigationView {
            List {
                searchSection
                commonFlightsSection
            }
            .navigationTitle("Track Flight")
            .sheet(item: $selectedFlight) { flightNumber in
                FlightView(flightNumber: flightNumber)
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var searchSection: some View {
        Section {
            HStack {
                TextField("Flight Number (e.g., UA837)", text: $searchText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onChange(of: searchText) { _, newValue in
                        // Uppercase conversion without forced text case
                        searchText = newValue.uppercased()
                    }
                    .onSubmit(searchFlight)
                
                if !searchText.isEmpty {
                    Button(action: searchFlight) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var commonFlightsSection: some View {
        Section("Common Carriers") {
            ForEach(Array(commonCarriers.keys.sorted()), id: \.self) { carrier in
                carrierRow(carrier)
            }
        }
    }
    
    private func carrierRow(_ carrier: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(carrier)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let flights = commonCarriers[carrier] {
                        ForEach(flights, id: \.self) { flight in
                            Button(action: {
                                searchText = flight
                                selectedFlight = flight
                                isSearchFocused = false
                            }) {
                                Text(flight)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FlightSearchView()
}
