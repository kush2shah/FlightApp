//
//  CodeshareInformationView.swift
//  FlightApp
//
//  Created by Kush Shah on 2/21/25.
//

import SwiftUI

struct CodeshareInformationView: View {
    let codeshares: [String]?
    
    var body: some View {
        if let codeshares = codeshares, !codeshares.isEmpty {
            Text("Also known as: \(codeshares.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
