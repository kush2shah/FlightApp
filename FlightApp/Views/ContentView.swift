//
//  ContentView.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isExplorePresented = false
    @State private var isPointsPresented = false
    @State private var isProfilePresented = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Flights")
                            .font(.system(size: 34, weight: .bold))
                        Spacer()
                        Button(action: { isProfilePresented.toggle() }) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Active flight card
                    ActiveFlightCard()
                        .padding(.horizontal)
                    
                    // Quick actions
                    QuickActionsView(
                        isExplorePresented: $isExplorePresented,
                        isPointsPresented: $isPointsPresented
                    )
                    
                    // Upcoming flights
                    UpcomingFlightsView()
                }
                .padding(.top)
            }
            
            // Bottom action bar
            BottomActionBar(
                isExplorePresented: $isExplorePresented,
                isPointsPresented: $isPointsPresented
            )
        }
        .sheet(isPresented: $isExplorePresented) {
            ExploreSheet()
        }
        .sheet(isPresented: $isPointsPresented) {
            PointsSheet()
        }
        .sheet(isPresented: $isProfilePresented) {
            ProfileSheet()
        }
    }
}

#Preview {
    ContentView()
}
