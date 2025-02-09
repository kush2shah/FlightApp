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
        HStack(spacing: 20) {
            Button(action: { isExplorePresented.toggle() }) {
                ActionButton(icon: "map.fill", title: "Explore")
            }
            
            Button(action: { isPointsPresented.toggle() }) {
                ActionButton(icon: "star.fill", title: "Points")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
        .cornerRadius(32)
        .shadow(radius: 10)
        .padding(.bottom)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
            Text(title)
                .font(.system(size: 16, weight: .medium))
        }
        .foregroundColor(.primary)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
    }
}
