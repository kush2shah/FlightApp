//
//  FlightSearchView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/10/25.
//

import SwiftUI

struct FlightSearchView: View {
    @State private var searchText = ""
    @State private var selectedFlight: String?
    @State private var recentSearches = ["UA837", "3K507", "AA100"]  // Eventually from UserDefaults
    
    // Common flight suggestions
    let commonFlights = [
        ["UA837", "UA60", "UA106"],
        ["3K507", "3K512", "3K781"],
        ["AA100", "AA137", "AA187"],
        ["DL401", "DL89", "DL837"]
    ]
    
    // Updated validation pattern
    private var isValidFlightNumber: Bool {
        // 2-3 characters followed by 1-4 digits
        let pattern = "^[A-Z0-9]{2,3}[0-9]{1,4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: searchText.uppercased())
    }
    
    var body: some View {
        NavigationView {
            List {
                // Search field
                Section {
                    TextField("Search flights (e.g., UA837, 3K507)", text: $searchText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                // Recent searches
                if !recentSearches.isEmpty {
                    Section("Recent") {
                        ForEach(recentSearches, id: \.self) { flight in
                            flightRow(flight)
                        }
                    }
                }
                
                // Common carriers
                Section("Common Flights") {
                    ForEach(commonFlights, id: \.self) { flights in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(flights, id: \.self) { flight in
                                    Button(action: { searchText = flight }) {
                                        Text(flight)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Track Flight")
            .fullScreenCover(item: $selectedFlight) { flightNumber in
                FlightView(flightNumber: flightNumber) {
                    // This closure is called when New Search is tapped
                    selectedFlight = nil
                }
            }
            .onChange(of: searchText) { _, newValue in
                if isValidFlightNumber {
                    selectedFlight = newValue.uppercased()
                }
            }
        }
    }
    
    private func flightRow(_ flightNumber: String) -> some View {
        Button(action: { searchText = flightNumber }) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
                Text(flightNumber)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
}

// Make String identifiable for fullScreenCover
extension String: Identifiable {
    public var id: String { self }
}

// Preview
struct FlightSearchView_Previews: PreviewProvider {
    static var previews: some View {
        FlightSearchView()
    }
}
