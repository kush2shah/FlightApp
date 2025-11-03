//
//  BookButton.swift
//  FlightApp
//
//  Created by Claude on 11/2/25.
//

import SwiftUI

struct BookButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("Book")
                    .font(.sfRounded(size: 14, weight: .semibold))
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
