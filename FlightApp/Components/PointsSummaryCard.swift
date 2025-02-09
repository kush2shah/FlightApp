//
//  PointsSummaryCard.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct PointsSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("482,650")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Total Points")
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    PointsSummaryCard()
}
