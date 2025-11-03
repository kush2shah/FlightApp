//
//  AirlineColorService.swift
//  FlightApp
//
//  Created by Claude Code on 10/12/25.
//

import SwiftUI
import UIKit

/// Service for extracting and caching dominant colors from airline logos
class AirlineColorService {
    static let shared = AirlineColorService()

    // Cache for extracted colors
    private var colorCache: [String: AirlineBrandColors] = [:]
    private let cacheQueue = DispatchQueue(label: "com.flightapp.colorcache")

    private init() {}

    /// Get brand colors for an airline
    func getBrandColors(for iataCode: String?) -> AirlineBrandColors {
        guard let code = iataCode else {
            return .default
        }

        // Check cache first
        if let cachedColors = cacheQueue.sync(execute: { colorCache[code] }) {
            return cachedColors
        }

        // Try to extract from logo
        if let logo = AirlineLogoService.shared.loadLogo(iataCode: code),
           let colors = extractDominantColors(from: logo) {
            cacheQueue.sync {
                colorCache[code] = colors
            }
            return colors
        }

        // Fallback to default
        return .default
    }

    /// Extract dominant colors from a logo image
    private func extractDominantColors(from image: UIImage) -> AirlineBrandColors? {
        guard image.cgImage != nil else { return nil }

        // Resize image for faster processing
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: size))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext(),
              let resizedCGImage = resizedImage.cgImage else {
            return nil
        }

        // Get pixel data
        let width = resizedCGImage.width
        let height = resizedCGImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Collect non-white, non-transparent colors
        var colors: [UIColor] = []

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                let a = CGFloat(pixelData[offset + 3]) / 255.0

                // Skip transparent pixels
                guard a > 0.5 else { continue }

                // Skip near-white pixels (background)
                let brightness = (r + g + b) / 3.0
                guard brightness < 0.9 else { continue }

                colors.append(UIColor(red: r, green: g, blue: b, alpha: a))
            }
        }

        guard !colors.isEmpty else { return nil }

        // Find the most vibrant/saturated color for primary
        let primaryColor = colors.max { c1, c2 in
            saturation(of: c1) < saturation(of: c2)
        } ?? colors.first!

        return AirlineBrandColors(
            color: Color(primaryColor)
        )
    }

    /// Calculate saturation of a UIColor
    private func saturation(of color: UIColor) -> CGFloat {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return saturation * brightness // Weight by brightness for more vibrant colors
    }

}

/// Brand color extracted from airline logo
struct AirlineBrandColors {
    let color: Color

    static let `default` = AirlineBrandColors(
        color: .blue
    )
}
