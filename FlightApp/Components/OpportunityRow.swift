//
//  OpportunityRow.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct OpportunityRow: View {
    let title: String
    let description: String
    let points: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("+\(points)")
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    OpportunityRow(
        title: "Dining Bonus",
        description: "5x points at restaurants",
        points: "2,500"
    )
}
