//
//  ClaudePromptBuilder.swift
//  FlightApp
//
//  Builds context-specific, concise prompts for Claude insights
//

import Foundation

enum InsightType {
    case awardAnalysis
    case destination
    case routeContext
    case aircraft
    case flightStatus
}

struct InsightContext {
    // Award context
    var awardData: [AwardOffer]?

    // Route context
    var origin: String?
    var destination: String?
    var distance: Double?
    var duration: TimeInterval?

    // Flight context
    var flightNumber: String?
    var airline: String?
    var aircraftType: String?
    var departureTime: Date?
    var arrivalTime: Date?

    // Destination context
    var destinationAirport: String?
    var destinationCity: String?
}

struct AwardOffer {
    let program: String
    let miles: Int
    let cabin: String
}

class ClaudePromptBuilder {

    /// Builds a concise, context-specific prompt for Claude
    static func buildPrompt(type: InsightType, context: InsightContext) -> (systemPrompt: String, userPrompt: String) {
        switch type {
        case .awardAnalysis:
            return buildAwardAnalysisPrompt(context: context)
        case .destination:
            return buildDestinationPrompt(context: context)
        case .routeContext:
            return buildRouteContextPrompt(context: context)
        case .aircraft:
            return buildAircraftPrompt(context: context)
        case .flightStatus:
            return buildFlightStatusPrompt(context: context)
        }
    }

    // MARK: - Award Analysis

    private static func buildAwardAnalysisPrompt(context: InsightContext) -> (String, String) {
        let system = """
        You provide factual award availability analysis. Rules:
        - Only compare data provided
        - No recommendations on which to book
        - No speculation about future availability
        - 2-3 sentences maximum
        """

        guard let awards = context.awardData, !awards.isEmpty else {
            return (system, "No award data available")
        }

        let awardList = awards.map { "\($0.program): \($0.miles) miles (\($0.cabin))" }.joined(separator: "\n")

        let user = """
        Compare these award options for \(context.origin ?? "origin") to \(context.destination ?? "destination"):

        \(awardList)

        Provide a brief factual comparison.
        """

        return (system, user)
    }

    // MARK: - Destination

    private static func buildDestinationPrompt(context: InsightContext) -> (String, String) {
        let system = """
        Provide interesting destination and airport facts. Rules:
        - Geographic location and time zone only
        - No recommendations or travel advice
        - No weather, visa, or safety information
        - 2 sentences maximum
        """

        let airport = context.destinationAirport ?? "unknown airport"
        let city = context.destinationCity ?? "the destination"

        let user = """
        Brief factual information about arriving at \(airport) in \(city).
        Include: location relationship and time zone vs US Eastern Time.
        """

        return (system, user)
    }

    // MARK: - Route Context

    private static func buildRouteContextPrompt(context: InsightContext) -> (String, String) {
        let system = """
        Describe route geography. Rules:
        - Use only provided distance/duration data
        - Geographic facts only (oceans crossed, continents)
        - No speculation about popularity or demand
        - 2-3 sentences maximum
        """

        let origin = context.origin ?? "origin"
        let destination = context.destination ?? "destination"
        let distanceStr = context.distance.map { String(format: "%.0f miles", $0) } ?? "unknown distance"
        let durationStr = context.duration.map { formatDuration($0) } ?? "unknown duration"

        let user = """
        Route: \(origin) to \(destination)
        Distance: \(distanceStr)
        Duration: \(durationStr)

        Describe the geographic routing briefly.
        """

        return (system, user)
    }

    // MARK: - Aircraft

    private static func buildAircraftPrompt(context: InsightContext) -> (String, String) {
        let system = """
        Provide aircraft facts. Rules:
        - Basic specifications only (manufacturer, category)
        - No opinions on comfort or service
        - No seat recommendations
        - 1-2 sentences maximum
        """

        let aircraft = context.aircraftType ?? "unknown aircraft"
        let airline = context.airline ?? "the airline"

        let user = """
        Aircraft: \(aircraft)
        Airline: \(airline)

        Brief factual description of this aircraft type.
        """

        return (system, user)
    }

    // MARK: - Flight Status

    private static func buildFlightStatusPrompt(context: InsightContext) -> (String, String) {
        let system = """
        Provide flight context. Rules:
        - Use only provided flight data
        - No speculation about delays or causes
        - Basic time zone and duration facts only
        - 2 sentences maximum
        """

        let flight = context.flightNumber ?? "this flight"
        let origin = context.origin ?? "origin"
        let destination = context.destination ?? "destination"

        var timeInfo = ""
        if let dep = context.departureTime, let arr = context.arrivalTime {
            let duration = arr.timeIntervalSince(dep)
            timeInfo = "Duration: \(formatDuration(duration))"
        }

        let user = """
        Flight: \(flight)
        Route: \(origin) to \(destination)
        \(timeInfo)

        Brief context about this flight routing.
        """

        return (system, user)
    }

    // MARK: - Helpers

    private static func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
