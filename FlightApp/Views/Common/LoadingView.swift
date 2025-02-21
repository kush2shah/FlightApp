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
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching for flight \(flightNumber)...")
                .foregroundColor(.secondary)
        }
    }
}
