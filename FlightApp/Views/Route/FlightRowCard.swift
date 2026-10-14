//
//  FlightRowCard.swift
//  FlightApp
//
//  A single flight in RouteView's "Explore Flights" list.
//

import SwiftUI

struct FlightRowCard: View {
    let flight: AeroFlight

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter
    }()

    private var airlineCode: String? {
        flight.operatorIata ?? flight.operatorIcao
    }

    private var departureDate: Date? {
        flight.scheduledOut.flatMap { ISO8601DateFormatter().date(from: $0) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                if let code = airlineCode {
                    AirlineLogoView(iataCode: code, size: 48)
                } else {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(flight.ident)
                        .font(.sfRounded(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    if let aircraftName = AircraftTypeService.shared.getAircraftName(from: flight.aircraftType) {
                        Text(aircraftName)
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 6, height: 6)
                        Text(status.label)
                            .font(.sfRounded(size: 12, weight: .medium))
                            .foregroundColor(status.color)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let scheduledOut = flight.scheduledOut {
                        Text(departureDate.map(Self.timeFormatter.string(from:)) ?? scheduledOut)
                            .font(.sfRounded(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Text("Departure")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            if let scheduledOut = flight.scheduledOut {
                Divider()
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(departureDate.map(Self.dateFormatter.string(from:)) ?? scheduledOut)
                        .font(.sfRounded(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }

    private var status: (label: String, color: Color) {
        let raw = flight.status.lowercased()
        if flight.isInProgress { return ("In Flight", .green) }
        if raw.contains("cancelled") { return ("Cancelled", .red) }
        if raw.contains("delayed") { return ("Delayed", .orange) }
        return ("Scheduled", .blue)
    }
}
