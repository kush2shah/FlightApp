//
//  Font+SFRounded.swift
//  FlightApp
//
//  Created by Kush Shah on 11/2/25.
//

import SwiftUI

extension Font {
    static func sfRounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
}
