//
//  SwiftUI+AnimationExtensions.swift
//  FlightApp
//
//  Created by Kush Shah on 5/4/25.
//

import SwiftUI

// MARK: - Animation Extensions

extension View {
    // Add a smooth appearing animation to any view
    func smoothAppear(delay: Double = 0, duration: Double = 0.5) -> some View {
        self
            .opacity(0)
            .offset(y: 20)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    _ = self
                        .opacity(1)
                        .offset(y: 0)
                }
            }
    }
    
    // Add flight-themed pulsing animation
    func pulseFlight(active: Bool = true, intensity: CGFloat = 1.0) -> some View {
        self.modifier(FlightPulseModifier(active: active, intensity: intensity))
    }
    
    // Airplane movement animation - simulates slight turbulence or movement
    func airplaneMovement(active: Bool = true, intensity: CGFloat = 1.0) -> some View {
        self.modifier(AirplaneMovementModifier(active: active, intensity: intensity))
    }
    
    // Add airline-themed color to a shape or text
    func airlineThemed(_ airlineCode: String?) -> some View {
        self.modifier(AirlineThemeModifier(airlineCode: airlineCode))
    }
    
    // Add springy feedback to buttons
    func springyButton() -> some View {
        self.buttonStyle(SpringyButtonStyle())
    }
    
    // Add a draggable gesture with haptic feedback
    func draggableWithFeedback(
        offsetX: Binding<CGFloat>,
        offsetY: Binding<CGFloat>,
        limitX: CGFloat? = nil,
        limitY: CGFloat? = nil
    ) -> some View {
        self.modifier(
            DraggableModifier(
                offsetX: offsetX,
                offsetY: offsetY,
                limitX: limitX,
                limitY: limitY
            )
        )
    }
    
    // Add a card-style appearance
    func flightCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // Add interactive scale effect on press
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressActionModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Custom Modifiers

// Pulsing animation modifier to draw attention to a view
struct FlightPulseModifier: ViewModifier {
    let active: Bool
    let intensity: CGFloat
    @State private var pulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulsing ? 1.0 + (0.05 * intensity) : 1.0)
            .opacity(pulsing ? 1.0 : 0.9)
            .onAppear {
                guard active else { return }
                
                withAnimation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                ) {
                    pulsing = true
                }
            }
    }
}

// Slight movement animation to simulate airplane turbulence
struct AirplaneMovementModifier: ViewModifier {
    let active: Bool
    let intensity: CGFloat
    @State private var offsetY: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: offsetY)
            .onAppear {
                guard active else { return }
                
                withAnimation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true)
                ) {
                    offsetY = 5 * intensity
                }
            }
    }
}

// Apply airline-specific theming to a view
struct AirlineThemeModifier: ViewModifier {
    let airlineCode: String?
    
    func body(content: Content) -> some View {
        Group {
            if let code = airlineCode {
                content
                    .foregroundColor(AirlineTheme.colors(for: code).primary)
            } else {
                content
                    .foregroundColor(.blue) // Default color
            }
        }
    }
}

// Springy button style with haptic feedback
struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
    }
}

// Draggable modifier with haptic feedback
struct DraggableModifier: ViewModifier {
    @Binding var offsetX: CGFloat
    @Binding var offsetY: CGFloat
    var limitX: CGFloat?
    var limitY: CGFloat?
    @GestureState private var gestureOffset: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .offset(x: offsetX + gestureOffset.width, y: offsetY + gestureOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Provide haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    .updating($gestureOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        if let limitX = limitX {
                            offsetX = min(max(offsetX + value.translation.width, -limitX), limitX)
                        } else {
                            offsetX += value.translation.width
                        }

                        if let limitY = limitY {
                            offsetY = min(max(offsetY + value.translation.height, -limitY), limitY)
                        } else {
                            offsetY += value.translation.height
                        }
                    }
            )
    }
}

// Press action modifier to detect press and release events
struct PressActionModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPress()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onRelease()
                    }
            )
    }
}
