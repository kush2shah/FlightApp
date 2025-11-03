//
//  CashPriceCard.swift
//  FlightApp
//
//  Simple card to display cash flight prices from Amadeus
//

import SwiftUI

struct CashPriceCard: View {
    let offer: FlightOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Date and airline
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    if let segment = offer.outbound?.segments.first {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                            Text(segment.departure.formattedFullDate)
                                .font(.sfRounded(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        // Flight info
                        HStack(spacing: 4) {
                            Text("\(segment.carrierCode) \(segment.number)")
                                .font(.sfRounded(size: 13))
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("\(segment.departure.formattedTime) → \(segment.arrival.formattedTime)")
                                .font(.sfRounded(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Book button
                BookButton {
                    HapticManager.shared.impact(.light)
                    // In the future, this could open a booking URL
                }
            }

            // Price and cabin details
            HStack {
                HStack(spacing: 4) {
                    Text(offer.formattedTotalPrice)
                        .font(.sfRounded(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(offer.primaryCabinDisplay)
                        .font(.sfRounded(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    Text("• \(stopText)")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // Flight details
            if let itinerary = offer.outbound {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(itinerary.formattedDuration)
                            .font(.sfRounded(size: 12))
                            .foregroundColor(.secondary)
                    }

                    if let segment = itinerary.segments.first {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Text("\(segment.departure.iataCode) → \(segment.arrival.iataCode)")
                                .font(.sfRounded(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private var stopText: String {
        offer.numberOfStops == 0 ? "Nonstop" : "\(offer.numberOfStops) stop\(offer.numberOfStops == 1 ? "" : "s")"
    }
}

// MARK: - FlightEndpoint Extension for Full Date
extension FlightEndpoint {
    var formattedFullDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
