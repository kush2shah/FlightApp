//
//  SettingsView.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var featureFlags = FeatureFlags.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Award Search", isOn: $featureFlags.isSeatsAeroEnabled)
                } header: {
                    Text("Features")
                } footer: {
                    Text("Enable award availability search powered by Seats.aero. Disable this if the service becomes unavailable or you prefer flight tracking only.")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
