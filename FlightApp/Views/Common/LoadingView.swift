//
//  LoadingView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/21/25.
//

import SwiftUI

struct LoadingView: View {
    let flightNumber: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Loading Icon - matches error view pattern
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "airplane")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .symbolEffect(.pulse, options: .repeating)
                )
            
            // Loading Message - matches error view structure
            VStack(spacing: 8) {
                Text("Loading Flight \(flightNumber)")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Searching for flight details...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress indicator to show active loading
            ProgressView()
                .tint(.blue)
        }
        .padding()
    }
}
