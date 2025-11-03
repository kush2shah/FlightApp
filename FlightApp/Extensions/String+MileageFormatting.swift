//
//  String+MileageFormatting.swift
//  FlightApp
//
//  Extension to format mileage/points costs with k notation
//

import Foundation

extension String {
    /// Format mileage cost with k notation for values >= 1000
    /// Examples: "1000" -> "1k", "30000" -> "30k", "65600" -> "65.6k", "999" -> "999"
    /// If value contains comma, use comma for values < 1000. Examples: "1,000" -> "1k", "999" -> "999"
    func formattedMileageCost() -> String {
        // Remove commas and whitespace
        let cleaned = self.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)

        // Try to parse as integer
        guard let value = Int(cleaned) else {
            return self // Return original if can't parse
        }

        if value >= 1000 {
            let thousands = Double(value) / 1000.0

            // If it's a whole number of thousands, don't show decimal
            if thousands.truncatingRemainder(dividingBy: 1.0) == 0 {
                return "\(Int(thousands))k"
            } else {
                // Show one decimal place
                return String(format: "%.1fk", thousands)
            }
        } else {
            // For values under 1000, use comma if original had comma
            if self.contains(",") {
                return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
            } else {
                return "\(value)"
            }
        }
    }
}
