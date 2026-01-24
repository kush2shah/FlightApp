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
            // Header: Price most prominent, airline and date below
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    // Price - most prominent
                    Text(offer.formattedTotalPrice)
                        .font(.sfRounded(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    
                    // Airline name
                    Text(offer.primaryAirlineName)
                        .font(.sfRounded(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let segment = offer.outbound?.segments.first {
                        // Date and flight info
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text(segment.departure.formattedFullDate)
                                .font(.sfRounded(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 4) {
                            Text("\(segment.carrierCode)\(segment.number)")
                                .font(.sfRounded(size: 12))
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("\(segment.departure.formattedTime) → \(segment.arrival.formattedTime)")
                                .font(.sfRounded(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Book button - opens airline website
                if let url = offer.airlineWebsiteUrl {
                    Link(destination: url) {
                        BookButton {
                            HapticManager.shared.impact(.light)
                        }
                    }
                } else {
                    BookButton {
                        HapticManager.shared.impact(.light)
                    }
                }
            }

            // Cabin and stop details
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Text(offer.primaryCabinDisplay)
                        .font(.sfRounded(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    Text("• \(stopText)")
                        .font(.sfRounded(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Flight details
                if let itinerary = offer.outbound {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(itinerary.formattedDuration)
                            .font(.sfRounded(size: 12))
                            .foregroundColor(.secondary)

                        if let segment = itinerary.segments.first {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

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
