//
//  FlightSearchView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/10/25.
//

import SwiftUI

// Make String identifiable for fullScreenCover
extension String: Identifiable {
    public var id: String { self }
}

struct FlightSearchView: View {
    @State private var searchText = ""
    @State private var selectedFlight: String?
    
    // Simplified data structure for quick testing
    let commonCarriers = [
        "United": ["UA837", "UA60", "UA106"],
        "Singapore": ["SQ12", "SQ31", "SQ11"],
        "American": ["AA100", "AA137", "AA187"]
    ]
    
    private var isValidFlightNumber: Bool {
        guard !searchText.isEmpty else { return false }
        // 2-3 characters followed by 1-4 digits
        let pattern = "^[A-Z0-9]{2,3}[0-9]{1,4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: searchText.uppercased())
    }
    
    var body: some View {
        NavigationView {
            List {
                searchSection
                commonFlightsSection
            }
            .navigationTitle("Track Flight")
            .fullScreenCover(item: $selectedFlight) { flightNumber in
                FlightView(flightNumber: flightNumber)
            }
        }
    }
    
    private var searchSection: some View {
        Section {
            TextField("Flight number (e.g., UA837)", text: $searchText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, newValue in
                    if isValidFlightNumber {
                        selectedFlight = newValue.uppercased()
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
                            Button(action: { searchText = flight }) {
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

// Preview
struct FlightSearchView_Previews: PreviewProvider {
    static var previews: some View {
        FlightSearchView()
    }
}
