//
//  AirlineLogoService.swift
//  FlightApp
//
//  Created by Kush Shah on 10/12/25.
//

import SwiftUI
import UIKit

/// Service for loading airline logos from the logos folder
class AirlineLogoService {
    static let shared = AirlineLogoService()

    // In-memory cache for loaded logos
    private var logoCache: [String: UIImage] = [:]
    private let cacheQueue = DispatchQueue(label: "com.flightapp.logocache")

    private init() {}

    /// Load airline logo by IATA code
    func loadLogo(iataCode: String) -> UIImage? {
        // Check cache first
        if let cachedLogo = cacheQueue.sync(execute: { logoCache[iataCode] }) {
            return cachedLogo
        }

        // Try to load from logos folder - multiple strategies
        var image: UIImage?

        // Strategy 1: Direct path with logos subfolder
        if let logoPath = Bundle.main.path(forResource: iataCode, ofType: "png", inDirectory: "logos") {
            image = UIImage(contentsOfFile: logoPath)
        }

        // Strategy 2: Try without subfolder
        if image == nil, let logoPath = Bundle.main.path(forResource: iataCode, ofType: "png") {
            image = UIImage(contentsOfFile: logoPath)
        }

        // Strategy 3: Check if it's in the main bundle with logos prefix
        if image == nil {
            image = UIImage(named: "logos/\(iataCode)")
        }

        // Strategy 4: Just try the name directly
        if image == nil {
            image = UIImage(named: iataCode)
        }

        guard let loadedImage = image else {
            print("⚠️ No logo found for airline: \(iataCode) (tried all strategies)")
            return nil
        }

        // Cache the loaded image
        cacheQueue.sync {
            logoCache[iataCode] = loadedImage
        }

        return loadedImage
    }

    /// Get SwiftUI Image for airline logo
    func getLogoImage(iataCode: String?) -> Image? {
        guard let code = iataCode,
              let uiImage = loadLogo(iataCode: code) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    /// Create a fallback view when logo isn't available
    static func fallbackLogoView(iataCode: String, size: CGFloat = 40) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(iataCode.prefix(2))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

/// SwiftUI View for displaying airline logos with fallback
struct AirlineLogoView: View {
    let iataCode: String?
    let size: CGFloat

    @State private var logoImage: Image?

    init(iataCode: String?, size: CGFloat = 40) {
        self.iataCode = iataCode
        self.size = size
    }

    var body: some View {
        Group {
            if let logoImage = logoImage {
                logoImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                    )
            } else if let code = iataCode {
                AirlineLogoService.fallbackLogoView(iataCode: code, size: size)
            } else {
                // Generic airplane icon fallback
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "airplane")
                            .font(.system(size: size * 0.5))
                            .foregroundColor(.secondary)
                    )
            }
        }
        .onAppear {
            loadLogo()
        }
    }

    private func loadLogo() {
        guard let code = iataCode else { return }

        // Load logo asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = AirlineLogoService.shared.getLogoImage(iataCode: code) {
                DispatchQueue.main.async {
                    self.logoImage = image
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AirlineLogoView(iataCode: "AA", size: 60)
        AirlineLogoView(iataCode: "BA", size: 60)
        AirlineLogoView(iataCode: "INVALID", size: 60)
        AirlineLogoView(iataCode: nil, size: 60)
    }
    .padding()
}
