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
    @StateObject private var awardPreferences = AwardPreferences.shared
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

            // Award Search Settings
            Section("Award Search") {
                Toggle(isOn: $featureFlags.isSeatsAeroEnabled) {
                    Label("Enable Award Search", systemImage: "star.fill")
                }

                if featureFlags.isSeatsAeroEnabled {
                    // Default search date range
                    Menu {
                        ForEach([7, 30, 60, 90], id: \.self) { days in
                            Button {
                                HapticManager.shared.impact(.soft)
                                awardPreferences.defaultDateRangeDays = days
                            } label: {
                                HStack {
                                    Text("\(days) days")
                                    if awardPreferences.defaultDateRangeDays == days {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Default Range: \(awardPreferences.defaultDateRangeDays) days", systemImage: "calendar")
                    }

                    // Default cabin classes
                    Menu {
                        Button {
                            HapticManager.shared.impact(.soft)
                            awardPreferences.defaultCabins = Set(CabinClass.allCases)
                        } label: {
                            HStack {
                                Text("All Cabins")
                                if awardPreferences.defaultCabins.count == CabinClass.allCases.count {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Button {
                            HapticManager.shared.impact(.soft)
                            awardPreferences.defaultCabins = [.business, .first]
                        } label: {
                            HStack {
                                Text("Premium Only")
                                if awardPreferences.defaultCabins == [.business, .first] {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Button {
                            HapticManager.shared.impact(.soft)
                            awardPreferences.defaultCabins = [.economy, .premiumEconomy]
                        } label: {
                            HStack {
                                Text("Economy Only")
                                if awardPreferences.defaultCabins == [.economy, .premiumEconomy] {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Label("Default Cabins", systemImage: "airplane.circle")
                    }

                    Toggle(isOn: $awardPreferences.showAllCabinsInResults) {
                        Label("Show All Cabins in Results", systemImage: "list.bullet")
                    }
                }
            }

            // About Section
            Section {
                Label("Version 0.1", systemImage: "info.circle")
            }
        } label: {
            // Simple button without any glass effects
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.primary)
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
