//
//  UpcomingFlightsView.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct UpcomingFlightsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        UpcomingFlightCard()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct UpcomingFlightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                Text("UA 837")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("Feb 15")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("SFO → NRT")
                    .font(.system(size: 18, weight: .bold))
                Text("11:20 AM - 4:45 PM")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}
