//
//  RouteStatusView.swift
//  FlightApp
//
//  Icon + title + message block used for RouteView's loading, error, and empty states.
//

import SwiftUI

struct RouteStatusView<Accessory: View>: View {
    let systemImage: String
    let tint: Color
    let title: String
    let message: String
    var pulsing = false
    @ViewBuilder var accessory: Accessory

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(tint.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 32))
                        .foregroundColor(tint)
                        .symbolEffect(.pulse, options: .repeating, isActive: pulsing)
                )

            VStack(spacing: 8) {
                Text(title)
                    .font(.sfRounded(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Text(message)
                    .font(.sfRounded(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            accessory
        }
        .frame(maxWidth: .infinity)
    }
}

extension RouteStatusView where Accessory == EmptyView {
    init(systemImage: String, tint: Color, title: String, message: String) {
        self.init(systemImage: systemImage, tint: tint, title: title, message: message) {
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        RouteStatusView(systemImage: "airplane", tint: .blue, title: "Loading Route", message: "Fetching route information...", pulsing: true) {
            ProgressView().tint(.blue)
        }
        RouteStatusView(systemImage: "exclamationmark.triangle.fill", tint: .orange, title: "Error Loading Route", message: "Could not load flights for this route")
    }
}
