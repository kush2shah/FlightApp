//
//  HapticManager.swift
//  FlightApp
//
//  Created by Kush Shah on 10/11/25.
//

import SwiftUI
import CoreHaptics

/// Manages haptic feedback throughout the app with aggressive, experience-defining patterns
class HapticManager {
    static let shared = HapticManager()

    // Feedback generators (pre-warmed for instant response)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    // CoreHaptics engine for custom patterns
    private var engine: CHHapticEngine?

    // User preferences
    @AppStorage("hapticIntensity") private var intensityLevel: HapticIntensity = .aggressive

    private init() {
        setupHapticsEngine()
        prepareGenerators()
    }

    private func setupHapticsEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()

            // Add handlers for engine stopped/reset
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }

            engine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }

            try engine?.start()
        } catch {
            print("Haptic engine creation error: \(error)")
        }
    }

    private func prepareGenerators() {
        // Prepare generators but don't call prepare() excessively
        // These will be prepared on-demand before use
    }

    // MARK: - Basic Haptics

    /// Heavy impact - for weighty glass interactions
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .heavy, intensity: CGFloat = 1.0) {
        guard intensityLevel != .off else { return }

        let adjustedIntensity = intensity * intensityLevel.multiplier

        // Use separate generators to avoid over-activation
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: adjustedIntensity)
    }

    func selectionChanged() {
        guard intensityLevel != .off else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard intensityLevel != .off else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: - Glass-Specific Patterns

    /// Glass "click" - heavy, decisive tap
    func glassClick() {
        impact(.heavy, intensity: 1.0)
    }

    /// Glass forming - appears with subtle build-up
    func glassForming() {
        guard intensityLevel != .off else { return }

        Task {
            impact(.soft, intensity: 0.6)
            try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
            impact(.medium, intensity: 0.7)
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
            selectionChanged()
        }
    }

    /// Glass breaking - shattering effect
    func glassBreaking() {
        guard intensityLevel != .off else { return }

        Task {
            impact(.heavy, intensity: 1.0)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            impact(.rigid, intensity: 0.9)
            try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
            impact(.medium, intensity: 0.6)
        }
    }

    /// Glass morphing - smooth transition
    func glassMorphing() {
        guard intensityLevel != .off else { return }
        impact(.soft, intensity: 0.7)
    }

    /// Glass settle - animation completion
    func glassSettle() {
        guard intensityLevel != .off else { return }
        impact(.light, intensity: 0.8)
    }

    // MARK: - Search Bar Haptics

    /// Search bar focused
    func searchBarFocused() {
        impact(.heavy, intensity: 0.9)
    }

    /// Character typed (aggressive typing feel)
    func characterTyped() {
        guard intensityLevel == .aggressive else { return }
        selectionChanged()
    }

    /// Search submitted - multi-stage feedback
    func searchSubmitted() {
        guard intensityLevel != .off else { return }

        Task {
            impact(.rigid, intensity: 1.0)
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            notificationOccurred(.success)
        }
    }

    /// Search cleared
    func searchCleared() {
        impact(.medium, intensity: 0.8)
    }

    // MARK: - Card Haptics

    /// Card appeared
    func cardAppeared(delay: TimeInterval = 0) {
        guard intensityLevel != .off else { return }

        Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            glassForming()
        }
    }

    /// Card tapped
    func cardTapped() {
        glassClick()
    }

    /// Card long pressed - building intensity
    func cardLongPressed() {
        guard intensityLevel != .off else { return }

        Task {
            impact(.medium, intensity: 0.5)
            try? await Task.sleep(nanoseconds: 100_000_000)
            impact(.medium, intensity: 0.7)
            try? await Task.sleep(nanoseconds: 100_000_000)
            impact(.heavy, intensity: 0.9)
        }
    }

    /// Card deleted
    func cardDeleted() {
        glassBreaking()
    }

    // MARK: - Sheet Haptics

    /// Sheet opened
    func sheetOpened() {
        impact(.heavy, intensity: 0.95)
    }

    /// Sheet closed
    func sheetClosed() {
        impact(.medium, intensity: 0.8)
    }

    /// Sheet at detent
    func sheetDetent() {
        selectionChanged()
    }

    // MARK: - Flurry Effects

    /// Flurry effect - rapid burst of haptics like particles scattering
    func flurry(count: Int = 5, duration: TimeInterval = 0.3) {
        guard intensityLevel != .off else { return }

        Task {
            let delayBetween = duration / Double(count)
            let delayNanoseconds = UInt64(delayBetween * 1_000_000_000)

            for i in 0..<count {
                // Vary intensity to create a dynamic feel - start strong, fade out
                let progress = Double(i) / Double(count)
                let intensity = 0.9 - (progress * 0.5) // 0.9 -> 0.4

                // Alternate between light and soft for texture
                let style: UIImpactFeedbackGenerator.FeedbackStyle = i % 2 == 0 ? .light : .soft
                impact(style, intensity: intensity)

                if i < count - 1 {
                    try? await Task.sleep(nanoseconds: delayNanoseconds)
                }
            }
        }
    }

    /// Intense flurry - more aggressive burst for dramatic moments
    func intenseFlurry() {
        guard intensityLevel != .off else { return }

        Task {
            // Quick burst of 7 haptics over 0.4 seconds
            impact(.rigid, intensity: 1.0)
            try? await Task.sleep(nanoseconds: 40_000_000) // 40ms
            impact(.medium, intensity: 0.9)
            try? await Task.sleep(nanoseconds: 35_000_000) // 35ms
            impact(.light, intensity: 0.8)
            try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
            impact(.soft, intensity: 0.7)
            try? await Task.sleep(nanoseconds: 30_000_000)
            impact(.light, intensity: 0.6)
            try? await Task.sleep(nanoseconds: 35_000_000)
            impact(.soft, intensity: 0.5)
            try? await Task.sleep(nanoseconds: 40_000_000)
            impact(.light, intensity: 0.3)
        }
    }

    /// Celebration flurry - uplifting burst for positive events
    func celebrationFlurry() {
        guard intensityLevel != .off else { return }

        Task {
            // Build up then scatter
            impact(.soft, intensity: 0.5)
            try? await Task.sleep(nanoseconds: 50_000_000)
            impact(.medium, intensity: 0.7)
            try? await Task.sleep(nanoseconds: 40_000_000)
            impact(.heavy, intensity: 0.9)
            try? await Task.sleep(nanoseconds: 30_000_000)

            // Scatter in quick succession
            for i in 0..<4 {
                let intensity = 0.7 - (Double(i) * 0.15)
                impact(.light, intensity: intensity)
                try? await Task.sleep(nanoseconds: 25_000_000)
            }
        }
    }

    // MARK: - Custom Patterns with CoreHaptics

    /// Play a custom haptic pattern
    func playCustomPattern(_ pattern: HapticPattern) {
        guard intensityLevel != .off, let engine = engine else { return }

        do {
            let hapticPattern = try CHHapticPattern(events: pattern.events, parameters: [])
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play custom haptic pattern: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum HapticIntensity: String, CaseIterable, Identifiable {
    case off = "Off"
    case subtle = "Subtle"
    case normal = "Normal"
    case aggressive = "Aggressive"

    var id: String { rawValue }

    var multiplier: CGFloat {
        switch self {
        case .off: return 0
        case .subtle: return 0.5
        case .normal: return 0.75
        case .aggressive: return 1.0
        }
    }

    var displayName: String {
        rawValue
    }
}

struct HapticPattern {
    let events: [CHHapticEvent]

    static let glassResonance = HapticPattern(events: [
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        ], relativeTime: 0),
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        ], relativeTime: 0.05, duration: 0.15)
    ])
}

// MARK: - SwiftUI View Extension

extension View {
    /// Add haptic feedback to button taps
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                HapticManager.shared.impact(style)
            }
        )
    }

    /// Add glass click haptic to interactions
    func glassClickHaptic() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                HapticManager.shared.glassClick()
            }
        )
    }
}
