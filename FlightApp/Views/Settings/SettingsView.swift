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
    @AppStorage("hapticIntensity") private var hapticIntensity: HapticIntensity = .aggressive

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
                    Picker("Haptic Intensity", selection: $hapticIntensity) {
                        ForEach(HapticIntensity.allCases) { intensity in
                            Text(intensity.displayName).tag(intensity)
                        }
                    }
                    .onChange(of: hapticIntensity) { _, newValue in
                        // Provide haptic feedback when changing the setting
                        HapticManager.shared.impact(.medium, intensity: newValue.multiplier)
                    }
                } header: {
                    Text("Haptics")
                } footer: {
                    Text("Control the intensity of haptic feedback throughout the app. Aggressive provides the most tactile experience.")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.1")
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
