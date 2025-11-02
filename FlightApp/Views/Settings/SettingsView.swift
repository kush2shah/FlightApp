//
//  SettingsView.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import SwiftUI

/// Settings button that displays a context menu with Liquid Glass effects
struct SettingsButton: View {
    @StateObject private var featureFlags = FeatureFlags.shared
    @AppStorage("hapticIntensity") private var hapticIntensity: HapticIntensity = .aggressive

    var body: some View {
        Menu {
            // Haptic Intensity Picker
            Menu {
                ForEach(HapticIntensity.allCases) { intensity in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            hapticIntensity = intensity
                            HapticManager.shared.impact(.medium, intensity: intensity.multiplier)
                        }
                    } label: {
                        HStack {
                            Text(intensity.displayName)
                            if hapticIntensity == intensity {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Haptic: \(hapticIntensity.displayName)", systemImage: "waveform")
            }

            // Features Section
            Section {
                Toggle(isOn: $featureFlags.isSeatsAeroEnabled) {
                    Label("Award Search", systemImage: "star.fill")
                }
            }

            // About Section
            Section {
                Label("Version 0.1", systemImage: "info.circle")
            }
        } label: {
            // Liquid Glass button design
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .glassEffect(.regular.interactive(), in: .circle)
        }
    }
}

#Preview {
    NavigationStack {
        VStack {
            Spacer()
            Text("Flight Tracker")
                .font(.largeTitle)
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                SettingsButton()
            }
        }
    }
}
