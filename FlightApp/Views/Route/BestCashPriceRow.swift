//
//  BestCashPriceRow.swift
//  FlightApp
//
//  The single best cash fare shown in RouteView's "Cash Fares" section.
//

import SwiftUI

struct BestCashPriceRow: View {
    let offer: FlightOffer

    private var firstSegment: FlightSegment? {
        offer.outbound?.segments.first
    }

    private var displayName: String {
        guard let segment = firstSegment else { return "Flight" }
        // If the airline name lookup fell back to the raw code, the flight number reads better
        return segment.airlineName == segment.carrierCode ? "Flight \(segment.flightNumber)" : segment.airlineName
    }

    var body: some View {
        HStack(spacing: 16) {
            if let code = firstSegment?.carrierCode {
                AirlineLogoView(iataCode: code, size: 56)
                    .frame(width: 56, height: 56)
            } else {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
                    .frame(width: 56, height: 56)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.sfRounded(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let departure = firstSegment?.departure {
                    Text(departure.formattedDate)
                        .font(.sfRounded(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if offer.numberOfStops == 0 {
                        Text("Nonstop")
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.green)
                    } else {
                        Text("\(offer.numberOfStops) \(offer.numberOfStops == 1 ? "stop" : "stops")")
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                    }
                    if let outbound = offer.outbound {
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(outbound.formattedDuration)
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(Int(offer.totalPrice))")
                    .font(.sfRounded(size: 32, weight: .bold))
                    .foregroundColor(.green)
                    .lineLimit(1)
                Text("USD")
                    .font(.sfRounded(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        )
    }
}
