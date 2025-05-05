//
//  FlightView+Extension.swift
//  FlightApp
//
//  Created by Kush Shah on 5/4/25.
//

import SwiftUI

// Extension to modify the FlightView to support enhanced visualizations
extension FlightView {
    // Add an enhanced mode toggle to the flight view
    func withEnhancedMode() -> some View {
        self.modifier(EnhancedModeModifier())
    }
}

// Modifier to add enhanced mode functionality
struct EnhancedModeModifier: ViewModifier {
    @AppStorage("useEnhancedMode") private var useEnhancedMode = false
    @Environment(\.dismiss) private var dismiss
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                // Add a toggle for enhanced mode in the toolbar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        useEnhancedMode.toggle()
                    }) {
                        if useEnhancedMode {
                            Label("Standard Mode", systemImage: "rectangle.on.rectangle")
                        } else {
                            Label("Enhanced Mode", systemImage: "sparkles")
                        }
                    }
                }
            }
    }
}

// View modifier to integrate enhanced components into FlightStatusView
struct EnhancedFlightStatusModifier: ViewModifier {
    let flight: AeroFlight
    let airline: AirlineProfile?
    @AppStorage("useEnhancedMode") private var useEnhancedMode = false
    
    func body(content: Content) -> some View {
        VStack {
            content
            
            if useEnhancedMode && flight.isInProgress {
                FlightProgressView(flight: flight, airline: airline)
                    .padding(.top)
                
                Divider()
                    .padding(.vertical)
                
                FlightRouteVisualization(flight: flight, airline: airline)
                    .frame(height: 250)
                    .padding(.bottom)
            }
        }
    }
}

// Extension for FlightStatusView to add enhanced visualizations
extension FlightStatusView {
    func withEnhancedVisualizations(flight: AeroFlight, airline: AirlineProfile?) -> some View {
        self.modifier(EnhancedFlightStatusModifier(flight: flight, airline: airline))
    }
}

// Extension for FlightDetailsSection to add points integration
extension FlightDetailsSection {
    func withPointsIntegration(flight: AeroFlight, airline: AirlineProfile?) -> some View {
        VStack {
            self
            
            if PointsIntegrationView.isDebugEnabled {
                PointsIntegrationView(flight: flight, airline: airline)
                    .padding(.top)
            }
        }
    }
}
