//
//  PointsOpportunitiesSection.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct PointsOpportunitiesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Points Opportunities")
                .font(.system(size: 16, weight: .medium))
            
            VStack(spacing: 12) {
                OpportunityCard(
                    icon: "fork.knife",
                    title: "5x Dining Points",
                    description: "Earn 5x points at restaurants until Feb 28",
                    pointsRange: "1,000-5,000"
                )
                
                OpportunityCard(
                    icon: "cart",
                    title: "Apple Bonus",
                    description: "10x points through shopping portal",
                    pointsRange: "2,000-20,000"
                )
                
                OpportunityCard(
                    icon: "creditcard",
                    title: "Card Offer",
                    description: "Spend $4,000, get 80,000 bonus points",
                    pointsRange: "80,000"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct OpportunityCard: View {
    let icon: String
    let title: String
    let description: String
    let pointsRange: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(pointsRange)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
