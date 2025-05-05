//
//  PointsIntegrationView.swift
//  FlightApp
//
//  Created by Kush Shah on 5/4/25.
//

import SwiftUI

// Model for frequent flyer programs
struct FrequentFlyerProgram: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let code: String
    let airline: String
    let airlineCode: String
    let membershipID: String?
    let pointsBalance: Int?
    let tier: String?
    let color: Color
    let secondaryColor: Color
    
    // Create a theme gradient based on the program's colors
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [color, secondaryColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Model for points redemption opportunities
struct PointsRedemption: Identifiable {
    let id = UUID()
    let program: FrequentFlyerProgram
    let originCode: String
    let destinationCode: String
    let routeDescription: String
    let pointsCost: Int
    let cashValue: Double
    let availableDates: [Date]
    let valuePerPoint: Double
    
    // Calculate the value per point (cents per point)
    var centsPerPoint: Double {
        return (cashValue / Double(pointsCost)) * 100
    }
    
    // Determine if this is a good redemption value
    var isGoodValue: Bool {
        return centsPerPoint >= 2.0 // Generally 2 cents per point or more is considered good
    }
}

// Main view for displaying points information
struct PointsIntegrationView: View {
    @StateObject private var viewModel = PointsViewModel()
    let flight: AeroFlight
    let airline: AirlineProfile?
    
    // Debug flag to determine if this feature should be visible
    // This should be set based on debug configuration
    #if DEBUG
    static let isDebugEnabled = true
    #else
    static let isDebugEnabled = false
    #endif
    
    var body: some View {
        Group {
            if Self.isDebugEnabled {
                pointsContentView
            } else {
                EmptyView() // Don't show anything in production builds
            }
        }
    }
    
    private var pointsContentView: some View {
        VStack(spacing: 20) {
            // Debug indicator
            HStack {
                Text("PREVIEW MODE")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
                
                Spacer()
            }
            
            // Section header
            HStack {
                Text("Points & Rewards")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    viewModel.refreshPointsData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                }
                .springyButton()
            }
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.programs.isEmpty {
                emptyStateView
            } else {
                programsView
                
                if !viewModel.redemptionOpportunities.isEmpty {
                    redemptionOpportunitiesView
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow, lineWidth: 1)
                .opacity(0.3)
        )
        .onAppear {
            viewModel.loadFrequentFlyerPrograms()
            if let airlineCode = airline?.icaoCode ?? airline?.iataCode {
                viewModel.findRedemptionOpportunities(for: flight, airlineCode: airlineCode)
            }
        }
    }
    
    // Loading state
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading points information...")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }
    
    // Empty state when no programs are added
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No frequent flyer programs linked")
                .font(.system(.headline, design: .rounded))
            
            Text("Link your frequent flyer programs to view point balances and redemption opportunities")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.showAddProgramSheet = true
            }) {
                Text("Add Program")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .springyButton()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // View for displaying frequent flyer programs
    private var programsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Programs")
                .font(.system(.headline, design: .rounded))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.programs) { program in
                        programCard(program)
                    }
                    
                    // Add program button
                    VStack {
                        Button(action: {
                            viewModel.showAddProgramSheet = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                                
                                Text("Add")
                                    .font(.system(.subheadline, design: .rounded))
                            }
                            .foregroundColor(.blue)
                            .frame(width: 90, height: 100)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                        .springyButton()
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $viewModel.showAddProgramSheet) {
            // Placeholder for the add program sheet
            VStack {
                Text("Add Frequent Flyer Program")
                    .font(.title)
                    .padding()
                
                Text("This feature is in development")
                    .foregroundColor(.secondary)
                    .padding()
                
                Button("Close") {
                    viewModel.showAddProgramSheet = false
                }
                .padding()
            }
        }
    }
    
    // Card for displaying frequent flyer program
    private func programCard(_ program: FrequentFlyerProgram) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Program logo placeholder
            HStack {
                Text(program.code)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(program.gradient)
            .cornerRadius(8)
            
            // Points balance
            if let balance = program.pointsBalance {
                Text("\(balance.formatted()) points")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
            }
            
            // Membership tier if available
            if let tier = program.tier {
                Text(tier)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    // View for displaying redemption opportunities
    private var redemptionOpportunitiesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Redemption Opportunities")
                    .font(.system(.headline, design: .rounded))
                
                Spacer()
                
                // Info button
                Button(action: {
                    // Show info about how redemption values are calculated
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            
            ForEach(viewModel.redemptionOpportunities) { opportunity in
                redemptionCard(opportunity)
            }
        }
    }
    
    // Card for displaying redemption opportunity
    private func redemptionCard(_ opportunity: PointsRedemption) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with program and value
            HStack {
                // Program indicator
                Text(opportunity.program.code)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(opportunity.program.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Spacer()
                
                // Value indicator
                HStack(spacing: 4) {
                    if opportunity.isGoodValue {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                    
                    Text(String(format: "%.1f¢ per point", opportunity.centsPerPoint))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(opportunity.isGoodValue ? .green : .secondary)
                        .fontWeight(opportunity.isGoodValue ? .bold : .regular)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(opportunity.isGoodValue ? Color.green.opacity(0.2) : Color.secondary.opacity(0.1))
                )
            }
            
            // Route information
            HStack(spacing: 12) {
                VStack(alignment: .center, spacing: 4) {
                    Text(opportunity.originCode)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .center, spacing: 4) {
                    Text(opportunity.destinationCode)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Points cost
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(opportunity.pointsCost.formatted()) pts")
                        .font(.system(.headline, design: .rounded))
                    
                    Text("$\(Int(opportunity.cashValue)) value")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            // Available dates preview
            HStack {
                Text("Available dates:")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                
                if opportunity.availableDates.count > 3 {
                    Text("\(formatDate(opportunity.availableDates[0])), \(formatDate(opportunity.availableDates[1])), and \(opportunity.availableDates.count - 2) more")
                        .font(.system(.caption, design: .rounded))
                } else {
                    Text(opportunity.availableDates.map { formatDate($0) }.joined(separator: ", "))
                        .font(.system(.caption, design: .rounded))
                }
            }
            
            // Book button
            Button(action: {
                viewModel.selectedRedemption = opportunity
                viewModel.showBookingSheet = true
            }) {
                Text("Book with Points")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(opportunity.program.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .springyButton()
            .disabled(true) // Always disable in preview mode
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
                    .opacity(0.5)
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .overlay(
            VStack {
                Spacer()
                Text("PREVIEW - Not available yet")
                    .font(.caption)
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .padding(.bottom, 8)
        )
        .sheet(isPresented: $viewModel.showBookingSheet) {
            VStack {
                Text("Booking Feature")
                    .font(.title)
                    .padding()
                
                Text("This feature is not yet available")
                    .foregroundColor(.secondary)
                    .padding()
                
                Button("Close") {
                    viewModel.showBookingSheet = false
                }
                .padding()
            }
        }
    }
    
    // Format date to readable string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// View model for points integration
class PointsViewModel: ObservableObject {
    @Published var programs: [FrequentFlyerProgram] = []
    @Published var redemptionOpportunities: [PointsRedemption] = []
    @Published var isLoading = false
    @Published var showAddProgramSheet = false
    @Published var showBookingSheet = false
    @Published var selectedRedemption: PointsRedemption? = nil
    
    // Load user's frequent flyer programs
    func loadFrequentFlyerPrograms() {
        isLoading = true
        
        // Simulate network request delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Mock data for demo purposes - in a real app, this would come from a user database
            self.programs = [
                FrequentFlyerProgram(
                    name: "United MileagePlus",
                    code: "MP",
                    airline: "United Airlines",
                    airlineCode: "UAL",
                    membershipID: "UA12345678",
                    pointsBalance: 48500,
                    tier: "Premier Silver",
                    color: Color(red: 0.0, green: 0.32, blue: 0.6),
                    secondaryColor: Color(red: 0.46, green: 0.68, blue: 0.81)
                ),
                FrequentFlyerProgram(
                    name: "American AAdvantage",
                    code: "AA",
                    airline: "American Airlines",
                    airlineCode: "AAL",
                    membershipID: "AA9876543",
                    pointsBalance: 32250,
                    tier: "Gold",
                    color: Color(red: 0.07, green: 0.22, blue: 0.44),
                    secondaryColor: Color(red: 0.72, green: 0.11, blue: 0.11)
                ),
                FrequentFlyerProgram(
                    name: "Delta SkyMiles",
                    code: "SM",
                    airline: "Delta Air Lines",
                    airlineCode: "DAL",
                    membershipID: "DL5551212",
                    pointsBalance: 67800,
                    tier: "Silver Medallion",
                    color: Color(red: 0.07, green: 0.22, blue: 0.44),
                    secondaryColor: Color(red: 0.72, green: 0.11, blue: 0.11)
                )
            ]
            
            self.isLoading = false
        }
    }
    
    // Find redemption opportunities for a specific flight
    func findRedemptionOpportunities(for flight: AeroFlight, airlineCode: String) {
        // In a real app, this would query an API to find available awards
        
        // Simulated redemption opportunities
        let calendar = Calendar.current
        let today = Date()
        
        // Generate some random future dates for availability
        let randomDates: [Date] = (1...5).map { days in
            calendar.date(byAdding: .day, value: days * 3, to: today)!
        }
        
        // Add mock redemption opportunities
        if let uaitedProgram = programs.first(where: { $0.airlineCode == "UAL" }) {
            redemptionOpportunities.append(
                PointsRedemption(
                    program: uaitedProgram,
                    originCode: flight.origin.displayCode,
                    destinationCode: flight.destination.displayCode,
                    routeDescription: "Economy Saver Award",
                    pointsCost: 25000,
                    cashValue: 450.0,
                    availableDates: randomDates,
                    valuePerPoint: 0.018
                )
            )
            
            redemptionOpportunities.append(
                PointsRedemption(
                    program: uaitedProgram,
                    originCode: flight.origin.displayCode,
                    destinationCode: flight.destination.displayCode,
                    routeDescription: "Business Saver Award",
                    pointsCost: 60000,
                    cashValue: 1800.0,
                    availableDates: Array(randomDates.prefix(2)),
                    valuePerPoint: 0.03
                )
            )
        }
        
        // Add mock redemption for American Airlines
        if let aaProgram = programs.first(where: { $0.airlineCode == "AAL" }) {
            redemptionOpportunities.append(
                PointsRedemption(
                    program: aaProgram,
                    originCode: flight.origin.displayCode,
                    destinationCode: flight.destination.displayCode,
                    routeDescription: "Main Cabin Web Special",
                    pointsCost: 20000,
                    cashValue: 380.0,
                    availableDates: randomDates,
                    valuePerPoint: 0.019
                )
            )
        }
    }
    
    // Refresh points data
    func refreshPointsData() {
        isLoading = true
        
        // Simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Update mock data
            for i in 0..<self.programs.count where i < self.programs.count {
                let randomChange = Int.random(in: -5000...8000)
                if let balance = self.programs[i].pointsBalance {
                    // Create new program with updated balance
                    let updatedProgram = FrequentFlyerProgram(
                        name: self.programs[i].name,
                        code: self.programs[i].code,
                        airline: self.programs[i].airline,
                        airlineCode: self.programs[i].airlineCode,
                        membershipID: self.programs[i].membershipID,
                        pointsBalance: max(0, balance + randomChange),
                        tier: self.programs[i].tier,
                        color: self.programs[i].color,
                        secondaryColor: self.programs[i].secondaryColor
                    )
                    self.programs[i] = updatedProgram
                }
            }
            
            self.isLoading = false
        }
    }
}

// Preview
struct PointsIntegrationView_Previews: PreviewProvider {
    static var previews: some View {
        let mockFlight = createMockFlight(
            ident: "UAL1234",
            operator_: "United Airlines",
            operatorIcao: "UAL",
            origin: createMockAirport(code: "SFO", city: "San Francisco"),
            destination: createMockAirport(code: "JFK", city: "New York"),
            progressPercent: 65
        )
        
        let mockAirline = AirlineProfile(
            name: "United Airlines",
            shortName: "United",
            iataCode: "UA",
            icaoCode: "UAL",
            callsign: "UNITED",
            country: "United States",
            location: "Chicago, Illinois",
            website: "https://www.united.com"
        )
        
        return PointsIntegrationView(flight: mockFlight, airline: mockAirline)
            .previewLayout(.sizeThatFits)
            .padding()
    }
    
    // Helper for creating mock data for previews
    static func createMockFlight(
        ident: String,
        operator_: String,
        operatorIcao: String?,
        origin: AeroAirport,
        destination: AeroAirport,
        progressPercent: Int
    ) -> AeroFlight {
        return AeroFlight(
            ident: ident,
            identIcao: nil,
            identIata: nil,
            faFlightId: "1234567",
            operator_: operator_,
            operatorIcao: operatorIcao,
            operatorIata: nil,
            flightNumber: "1234",
            registration: nil,
            atcIdent: nil,
            inboundFaFlightId: nil,
            codeshares: nil,
            codeshares_iata: nil,
            origin: origin,
            destination: destination,
            departureDelay: nil,
            arrivalDelay: nil,
            filedEte: nil,
            progressPercent: progressPercent,
            status: "en route",
            aircraftType: "B738",
            routeDistance: 2500,
            filedAirspeed: 450,
            filedAltitude: 35000,
            route: nil,
            baggageClaim: nil,
            gateOrigin: nil,
            gateDestination: nil,
            terminalOrigin: nil,
            terminalDestination: nil,
            flightType: .airline,
            scheduledOut: ISO8601DateFormatter().string(from: Date()),
            estimatedOut: nil,
            actualOut: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-2 * 3600)),
            scheduledOff: nil,
            estimatedOff: nil,
            actualOff: nil,
            scheduledOn: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3 * 3600)),
            estimatedOn: nil,
            actualOn: nil,
            scheduledIn: nil,
            estimatedIn: nil,
            actualIn: nil,
            diverted: false,
            cancelled: false,
            blocked: false,
            positionOnly: false
        )
    }
    
    static func createMockAirport(code: String, city: String?) -> AeroAirport {
        return AeroAirport(
            code: code,
            codeIcao: nil,
            codeIata: code,
            timezone: "America/Los_Angeles",
            name: "\(city ?? code) International Airport",
            city: city
        )
    }
}
