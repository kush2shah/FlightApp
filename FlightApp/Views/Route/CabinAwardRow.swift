//
//  CabinAwardRow.swift
//  FlightApp
//
//  Nested award dropdowns for RouteView: Cabin → Program → Dates.
//

import SwiftUI

/// Cabin-level row that expands to show programs
struct CabinAwardRow: View {
    let cabin: CabinClass
    let awards: [AwardAvailability]

    @State private var isExpanded = false

    private var programGroups: [(program: String, awards: [AwardAvailability])] {
        awards.groupedByProgram(for: cabin)
    }

    var body: some View {
        let groups = programGroups

        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.impact(.light)
            }) {
                HStack(spacing: 16) {
                    Image(systemName: cabin.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cabin.displayName)
                            .font(.sfRounded(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text("\(groups.count) program\(groups.count == 1 ? "" : "s")")
                            .font(.sfRounded(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    if let cost = awards.cheapest(for: cabin)?.getMileageCost(for: cabin) {
                        HStack(spacing: 4) {
                            Text("from")
                                .font(.sfRounded(size: 11))
                                .foregroundColor(.secondary)
                            PointsLabel(cost: cost, size: 20, unitSize: 13)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }

                    ExpandChevron(isExpanded: isExpanded, size: 14)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 76)

                    ForEach(Array(groups.enumerated()), id: \.element.program) { index, group in
                        ProgramAwardGroup(programName: group.program, awards: group.awards, cabin: cabin)

                        if index < groups.count - 1 {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// Program-level row within a cabin that expands to show more dates
struct ProgramAwardGroup: View {
    let programName: String
    let awards: [AwardAvailability]
    let cabin: CabinClass

    /// Additional dates shown when expanded
    static let maxAdditionalAwards = 5

    @State private var isExpanded = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    var body: some View {
        // Cheapest first; the first one is the headline fare
        let sorted = awards.sortedByCost(for: cabin)
        let additional = Array(sorted.dropFirst())
        let visibleAdditional = additional.prefix(Self.maxAdditionalAwards)

        VStack(spacing: 0) {
            if let best = sorted.first {
                bestFareRow(best, additionalCount: additional.count)
            }

            if isExpanded && !additional.isEmpty {
                VStack(spacing: 0) {
                    ForEach(visibleAdditional) { award in
                        VStack(spacing: 0) {
                            additionalFareRow(award)

                            if award.id != visibleAdditional.last?.id {
                                Divider()
                                    .padding(.leading, 88)
                            }
                        }
                    }

                    if additional.count > Self.maxAdditionalAwards {
                        HStack {
                            Text("+\(additional.count - Self.maxAdditionalAwards) more dates available")
                                .font(.sfRounded(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 88)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.03))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func bestFareRow(_ best: AwardAvailability, additionalCount: Int) -> some View {
        Button(action: {
            guard additionalCount > 0 else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            HapticManager.shared.impact(.light)
        }) {
            HStack(spacing: 12) {
                // Indent under the cabin icon
                Color.clear.frame(width: 40)

                AirlineLogoView(iataCode: MileageProgramService.shared.getImageName(from: best.source), size: 36)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(programName)
                            .font(.sfRounded(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if additionalCount > 0 {
                            Text("+\(additionalCount)")
                                .font(.sfRounded(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }

                    if let date = best.parsedDate {
                        Text(Self.dateFormatter.string(from: date))
                            .font(.sfRounded(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                if let cost = best.getMileageCost(for: cabin) {
                    PointsLabel(cost: cost, size: 16, unitSize: 11)
                        .fixedSize(horizontal: true, vertical: false)
                }

                if additionalCount > 0 {
                    ExpandChevron(isExpanded: isExpanded, size: 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.02))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func additionalFareRow(_ award: AwardAvailability) -> some View {
        HStack(spacing: 12) {
            // Double indent
            Color.clear.frame(width: 88)

            VStack(alignment: .leading, spacing: 4) {
                if let date = award.parsedDate {
                    Text(Self.dateFormatter.string(from: date))
                        .font(.sfRounded(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                if let seats = award.getRemainingSeats(for: cabin) {
                    Text("\(seats) seat\(seats == 1 ? "" : "s") left")
                        .font(.sfRounded(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let cost = award.getMileageCost(for: cabin) {
                PointsLabel(cost: cost, size: 14, unitSize: 10)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.01))
    }
}

// MARK: - Small Pieces

/// "35k pts"
private struct PointsLabel: View {
    let cost: String
    let size: CGFloat
    let unitSize: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            Text(cost)
                .font(.sfRounded(size: size, weight: .bold))
                .foregroundColor(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("pts")
                .font(.sfRounded(size: unitSize, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

private struct ExpandChevron: View {
    let isExpanded: Bool
    let size: CGFloat

    var body: some View {
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(.secondary.opacity(0.5))
            .frame(width: size)
    }
}
