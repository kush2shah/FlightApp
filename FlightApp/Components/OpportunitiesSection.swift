//
//  OpportunitiesSection.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct OpportunitiesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Point Opportunities")
                .font(.headline)
            
            VStack(spacing: 12) {
                OpportunityRow(
                    title: "Dining Bonus",
                    description: "5x points at restaurants",
                    points: "2,500"
                )
                OpportunityRow(
                    title: "Shopping Portal",
                    description: "Apple purchases",
                    points: "3,500"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    OpportunitiesSection()
}
