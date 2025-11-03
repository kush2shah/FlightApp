//
//  GlassEffectContainer.swift
//  FlightApp
//
//  Created by Kush Shah on 10/11/25.
//

import SwiftUI

/// Constants for glass effects
struct GlassConstants {
    static let defaultCornerRadius: CGFloat = 20
    static let cardCornerRadius: CGFloat = 24
    static let searchBarCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 16

    static let defaultSpacing: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
}

/// View extension for branded glass effects
extension View {
    /// Apply a branded glass effect using airline color with native glass material
    /// Uniform color wash across entire card for consistent branding
    func brandedGlassEffect(
        colors: AirlineBrandColors?,
        cornerRadius: CGFloat = 16,
        intensity: CGFloat = 0.3
    ) -> some View {
        self
            .background(
                ZStack {
                    // Native iOS glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Color wash behind content
                    if let colors = colors {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(colors.color.opacity(intensity))
                    }
                }
            )
    }
}
