//
//  PrivacyPolicyView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/11/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                privacySection(
                    title: "Data We Collect",
                    icon: "doc.text.fill",
                    content: "FlightApp only collects flight search queries temporarily to fetch real-time flight data from public APIs. No personal information is collected or stored."
                )

                privacySection(
                    title: "How We Use Data",
                    icon: "arrow.triangle.2.circlepath",
                    content: "Your flight searches are used solely to retrieve public flight information from FlightAware's AeroAPI. Search history is stored locally on your device for convenience."
                )

                privacySection(
                    title: "Data Storage",
                    icon: "externaldrive.fill",
                    content: "All app preferences and search history remain on your device. We use local caching to improve performance and reduce API calls."
                )

                privacySection(
                    title: "Third-Party Services",
                    icon: "network",
                    content: "FlightApp uses FlightAware's AeroAPI to fetch flight data. Flight queries are sent to their servers to retrieve public flight information. Please review FlightAware's privacy policy for details on their data practices."
                )

                privacySection(
                    title: "Your Control",
                    icon: "hand.raised.fill",
                    content: "You can clear your search history at any time from the app settings. No data is synced to cloud services or shared with third parties."
                )

                privacySection(
                    title: "Updates",
                    icon: "arrow.clockwise.circle.fill",
                    content: "This privacy policy may be updated as the app evolves. Major changes will be communicated through app updates."
                )
            }
            .padding(24)
        }
    }

    private func privacySection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
