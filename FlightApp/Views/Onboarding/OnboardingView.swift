//
//  OnboardingView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var showPrivacyPolicy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with icon and title
            VStack(alignment: .leading, spacing: 16) {
                // App icon
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.48, blue: 1.0),
                                Color(red: 0.3, green: 0.6, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("FlightTracky")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 32)

            Divider()
                .padding(.bottom, 24)

            // Features list
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    featureRow(
                        icon: "airplane.departure",
                        title: "Real-Time Flight Tracking",
                        description: "Track any flight in real-time with live status updates, departure and arrival times, and current progress."
                    )

                    featureRow(
                        icon: "map.fill",
                        title: "Interactive Route Maps",
                        description: "Visualize flight paths with detailed waypoints, airports, and navigation points on beautiful interactive maps."
                    )

                    featureRow(
                        icon: "airplane.circle.fill",
                        title: "Comprehensive Details",
                        description: "Access detailed information about aircraft, airports, gates, terminals, and more for every flight."
                    )

                    featureRow(
                        icon: "lock.shield.fill",
                        title: "Privacy First",
                        description: "Your searches stay private on your device. We only use APIs to fetch public flight data."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            // Bottom actions - pinned to bottom
            VStack(spacing: 12) {
                Divider()
                    .padding(.bottom, 8)

                Button {
                    HapticManager.shared.glassClick()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    HapticManager.shared.impact(.soft)
                    showPrivacyPolicy = true
                } label: {
                    Text("Privacy Policy")
                        .font(.subheadline)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
                    .navigationTitle("Privacy Policy")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showPrivacyPolicy = false
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
