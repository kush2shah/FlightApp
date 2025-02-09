//
//  FlightCard.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct FlightCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("SFO → NRT")
                    .font(.headline)
                Spacer()
                Text("UA 837")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Feb 15, 2025")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    FlightCard()
}
