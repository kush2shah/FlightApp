//
//  BottomActionBar.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct BottomActionBar: View {
    @Binding var isExplorePresented: Bool
    @Binding var isPointsPresented: Bool
    
    var body: some View {
        HStack(spacing: 32) {
            ActionBarButton(
                icon: "map.fill",
                title: "Explore",
                action: { isExplorePresented.toggle() }
            )
            
            ActionBarButton(
                icon: "star.fill",
                title: "Points",
                action: { isPointsPresented.toggle() }
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial)
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct ActionBarButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.primary)
            .contentShape(Rectangle())
        }
    }
}
