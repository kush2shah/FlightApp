//
//  FlightErrorView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/11/25.
//

import SwiftUI

struct FlightErrorView: View {
    let flightNumber: String
    let errorMessage: String
    let onRetry: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Error Icon
            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                )
            
            // Error Message
            VStack(spacing: 8) {
                Text("Flight Not Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Suggestions
            VStack(alignment: .leading, spacing: 16) {
                Text("Try:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    SuggestionRow(
                        icon: "clock.arrow.circlepath",
                        text: "Check back closer to departure time"
                    )
                    SuggestionRow(
                        icon: "magnifyingglass",
                        text: "Verify the flight number format"
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 5)
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: onBack) {
                    Text("Back to Search")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
