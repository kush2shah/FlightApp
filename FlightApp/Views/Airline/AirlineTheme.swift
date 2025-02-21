//
//  AirlineTheme.swift
//  FlightApp
//
//  Created by Kush Shah on 2/20/25.
//

import SwiftUI

// Struct to manage airline brand colors and theme
struct AirlineTheme {
    // Primary color mapping for major airlines
    static let airlineColors: [String: (primary: Color, secondary: Color)] = [
        // Major US Airlines
        "AAL": (.init(red: 0.07, green: 0.22, blue: 0.44), .init(red: 0.72, green: 0.11, blue: 0.11)), // American Airlines - Navy & Red
        "UAL": (.init(red: 0.0, green: 0.32, blue: 0.6), .init(red: 0.46, green: 0.68, blue: 0.81)),  // United - Blue
        "DAL": (.init(red: 0.07, green: 0.22, blue: 0.44), .init(red: 0.72, green: 0.11, blue: 0.11)), // Delta - Dark Blue & Red
        "SWA": (.init(red: 0.0, green: 0.44, blue: 0.76), .init(red: 0.96, green: 0.68, blue: 0.0)),  // Southwest - Blue & Yellow
        "JBU": (.init(red: 0.0, green: 0.58, blue: 0.86), .init(red: 0.96, green: 0.67, blue: 0.0)),  // JetBlue - Blue & Orange
        "ASA": (.init(red: 0.0, green: 0.31, blue: 0.49), .init(red: 0.0, green: 0.65, blue: 0.31)),  // Alaska - Navy & Green
        
        // Major European Airlines
        "BAW": (.init(red: 0.07, green: 0.22, blue: 0.44), .init(red: 0.72, green: 0.11, blue: 0.11)), // British Airways - Navy & Red
        "DLH": (.init(red: 0.0, green: 0.32, blue: 0.65), .init(red: 0.96, green: 0.87, blue: 0.0)),  // Lufthansa - Blue & Yellow
        "AFR": (.init(red: 0.0, green: 0.12, blue: 0.38), .init(red: 0.72, green: 0.11, blue: 0.11)), // Air France - Navy & Red
        "KLM": (.init(red: 0.0, green: 0.43, blue: 0.69), .init(red: 1.0, green: 1.0, blue: 1.0)),    // KLM - Light Blue & White
        "IBE": (.init(red: 0.87, green: 0.0, blue: 0.0), .init(red: 0.96, green: 0.87, blue: 0.0)),   // Iberia - Red & Yellow
        
        // Asian/Pacific Airlines
        "SIA": (.init(red: 0.96, green: 0.87, blue: 0.0), .init(red: 0.0, green: 0.32, blue: 0.65)),  // Singapore Airlines - Yellow & Blue
        "CPA": (.init(red: 0.0, green: 0.32, blue: 0.54), .init(red: 0.39, green: 0.58, blue: 0.93)), // Cathay Pacific - Dark Blue & Light Blue
        "ANA": (.init(red: 0.0, green: 0.12, blue: 0.38), .init(red: 0.39, green: 0.58, blue: 0.93)), // ANA - Navy & Light Blue
        "JAL": (.init(red: 0.87, green: 0.0, blue: 0.0), .init(red: 1.0, green: 1.0, blue: 1.0)),     // Japan Airlines - Red & White
        "QFA": (.init(red: 0.87, green: 0.0, blue: 0.0), .init(red: 1.0, green: 1.0, blue: 1.0)),     // Qantas - Red & White
        
        // Middle Eastern Airlines
        "UAE": (.init(red: 0.0, green: 0.4, blue: 0.0), .init(red: 0.87, green: 0.0, blue: 0.0)),     // Emirates - Green & Red
        "QTR": (.init(red: 0.57, green: 0.0, blue: 0.17), .init(red: 0.39, green: 0.58, blue: 0.93)), // Qatar - Burgundy & Light Blue
        "ETD": (.init(red: 0.96, green: 0.87, blue: 0.0), .init(red: 0.0, green: 0.12, blue: 0.38))   // Etihad - Gold & Navy
    ]
    
    // Get brand colors for a specific airline code
    static func colors(for code: String) -> (primary: Color, secondary: Color) {
        // First look for the specific code in our mapping
        if let colors = airlineColors[code] {
            return colors
        }
        
        // If not found, generate harmonious colors based on the code
        return generateColors(from: code)
    }
    
    // Generate aesthetically pleasing, harmonious colors from a string
    private static func generateColors(from code: String) -> (primary: Color, secondary: Color) {
        // Hash the string to get consistent but pseudo-random values
        let hash = code.utf8.reduce(0) { $0 &+ Int($1) }
        
        // Use the golden ratio to create aesthetically pleasing hues
        // that are properly spaced around the color wheel
        let goldenRatio: Double = 0.618033988749895
        var hue = Double(hash % 360) / 360.0
        
        // Primary color - more saturated, medium brightness
        let primary = Color(
            hue: hue,
            saturation: 0.65 + Double(hash % 20) / 100.0, // 0.65-0.85
            brightness: 0.75 + Double(hash % 15) / 100.0  // 0.75-0.90
        )
        
        // Secondary color - Calculate a complementary or analogous color
        // Use 30% chance of complementary, 70% chance of analogous
        if hash % 10 < 3 {
            // Complementary (opposite on color wheel)
            hue = (hue + 0.5).truncatingRemainder(dividingBy: 1.0)
        } else {
            // Analogous (adjacent on color wheel using golden ratio)
            hue = (hue + goldenRatio).truncatingRemainder(dividingBy: 1.0)
        }
        
        let secondary = Color(
            hue: hue,
            saturation: 0.6 + Double(hash % 25) / 100.0,  // 0.6-0.85
            brightness: 0.7 + Double(hash % 20) / 100.0   // 0.7-0.9
        )
        
        return (primary, secondary)
    }
    
    // Generate a gradient from a primary and secondary color
    static func gradient(for code: String) -> LinearGradient {
        let colors = self.colors(for: code)
        
        return LinearGradient(
            gradient: Gradient(colors: [colors.primary, colors.secondary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
