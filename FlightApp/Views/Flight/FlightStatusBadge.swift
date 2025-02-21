//
//  FlightStatusBadge.swift
//  FlightApp
//
//  Created by Kush Shah on 2/21/25.
//

import SwiftUI

struct FlightStatusBadge: View {
    let status: String
    let color: Color
    
    init(status: String, color: Color = .green) {
        self.status = status
        self.color = color
    }
    
    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}
