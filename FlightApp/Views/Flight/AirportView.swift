//
//  AirportView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/21/25.
//

import SwiftUI

struct AirportView: View {
    let code: String
    let city: String
    let alignment: HorizontalAlignment
    
    var body: some View {
        VStack(alignment: alignment) {
            Text(code)
            Text(city)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
