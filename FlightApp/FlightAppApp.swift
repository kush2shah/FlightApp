//
//  FlightAppApp.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

@main
struct FlightAppApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .interactiveDismissDisabled()
                        .onDisappear {
                            hasCompletedOnboarding = true
                        }
                }
                .onAppear {
                    if !hasCompletedOnboarding {
                        // Small delay to let the main view appear first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showOnboarding = true
                        }
                    }
                }
        }
    }
}
