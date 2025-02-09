//
//  RecentActivitySection.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 16, weight: .medium))
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "airplane.circle.fill",
                    title: "SFO → NRT",
                    details: "Business Class",
                    points: "-75,000",
                    date: "Jan 28"
                )
                
                ActivityRow(
                    icon: "cart.circle.fill",
                    title: "Apple Store",
                    details: "Shopping Portal",
                    points: "+3,500",
                    date: "Jan 25"
                )
                
                ActivityRow(
                    icon: "fork.knife.circle.fill",
                    title: "Dining Bonus",
                    details: "State Bird Provisions",
                    points: "+500",
                    date: "Jan 22"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let details: String
    let points: String
    let date: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                Text(details)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(points)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(points.hasPrefix("+") ? .green : .primary)
                Text(date)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}
