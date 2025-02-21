//
//  AirlineProfileView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/20/25.
//

import SwiftUI

// Model to represent airline information in the app
struct AirlineProfile {
    let name: String
    let shortName: String?
    let iataCode: String?
    let icaoCode: String?
    let callsign: String?
    let country: String?
    let location: String?
    let website: String?
    
    // Computed property to generate a unique identifier for the airline
    var id: String {
        return icaoCode ?? iataCode ?? name
    }
    
    // Generate a gradient based on the airline brand colors
    var themeGradient: LinearGradient {
        // Use the ICAO code (or IATA if ICAO is nil) to get the brand colors
        let code = icaoCode ?? iataCode ?? ""
        return AirlineTheme.gradient(for: code)
    }
}

struct AirlineProfileView: View {
    let airline: AirlineProfile
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient header that uses the airline's theme colors
            header
                .frame(height: 8)
            
            // Main content with airline information
            content
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var header: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(airline.themeGradient)
            .frame(maxWidth: .infinity)
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Airline name and code
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(airline.name)
                        .font(.system(.headline, design: .rounded))
                    
                    if let shortName = airline.shortName, shortName != airline.name {
                        Text(shortName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                codeDisplay
            }
            
            // Additional information
            if airline.callsign != nil || airline.country != nil {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    if let callsign = airline.callsign {
                        infoRow(icon: "radio", label: "Callsign", value: callsign)
                    }
                    
                    if let country = airline.country {
                        infoRow(icon: "globe", label: "Country", value: country)
                    }
                    
                    if let location = airline.location, location != airline.country {
                        infoRow(icon: "mappin.and.ellipse", label: "Base", value: location)
                    }
                    
                    if let website = airline.website, let url = URL(string: website) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Text("Visit Website")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var codeDisplay: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let iataCode = airline.iataCode {
                Text(iataCode)
                    .font(.system(.headline, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(airline.themeGradient.opacity(0.2))
                    )
            }
            
            if let icaoCode = airline.icaoCode {
                Text(icaoCode)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(.subheadline, design: .rounded))
            
            Spacer()
        }
    }
}

// Preview
struct AirlineProfileView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AirlineProfileView(airline:
                AirlineProfile(
                    name: "United Airlines",
                    shortName: "United",
                    iataCode: "UA",
                    icaoCode: "UAL",
                    callsign: "UNITED",
                    country: "United States",
                    location: "Chicago, Illinois",
                    website: "https://www.united.com"
                )
            )
            
            AirlineProfileView(airline:
                AirlineProfile(
                    name: "Singapore Airlines",
                    shortName: nil,
                    iataCode: "SQ",
                    icaoCode: "SIA",
                    callsign: "SINGAPORE",
                    country: "Singapore",
                    location: nil,
                    website: "https://www.singaporeair.com"
                )
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// Extension to add Equatable conformance to AirlineProfile
extension AirlineProfile: Equatable {
    static func == (lhs: AirlineProfile, rhs: AirlineProfile) -> Bool {
        return lhs.id == rhs.id
    }
}

// Extension to add Hashable conformance to AirlineProfile
extension AirlineProfile: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    AirlineProfileView_Previews.previews
}
