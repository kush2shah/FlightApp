//
//  PointsSheet.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct PointsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Points Balance
                    PointsBalanceCard()
                    
                    // Recent Activity
                    RecentActivitySection()
                    
                    // Opportunities
                    PointsOpportunitiesSection()
                }
                .padding()
            }
            .navigationTitle("Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PointsBalanceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Balance")
                .font(.system(size: 16, weight: .medium))
            
            Text("482,650")
                .font(.system(size: 34, weight: .bold))
            
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
                Text("+2,500 this month")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}
