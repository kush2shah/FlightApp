//
//  GlassEffectContainer.swift
//  FlightApp
//
//  Created by Kush Shah on 10/11/25.
//

import SwiftUI

/// A container that groups liquid glass effect elements with proper spacing
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
    }
}

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
