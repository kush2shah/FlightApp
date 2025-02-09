//
//  QuickActionsView.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct QuickActionsView: View {
    @Binding var isExplorePresented: Bool
    @Binding var isPointsPresented: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "map.fill",
                    title: "Explore",
                    color: .purple
                ) {
                    isExplorePresented.toggle()
                }
                
                QuickActionButton(
                    icon: "star.fill",
                    title: "Points",
                    color: .orange
                ) {
                    isPointsPresented.toggle()
                }
                
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Stats",
                    color: .green
                ) {
                    // Action
                }
            }
            .padding(.horizontal)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 100, height: 100)
            .background(color)
            .cornerRadius(20)
        }
    }
}


