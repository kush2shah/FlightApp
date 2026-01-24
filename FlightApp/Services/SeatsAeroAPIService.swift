//
//  SeatsAeroAPIService.swift
//  FlightApp
//
//  Created by Kush Shah on 10/7/25.
//

import Foundation

enum SeatsAeroAPIError: LocalizedError {
    case featureDisabled
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case noResultsFound
    case rateLimitExceeded
    case unauthorized
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "Award search is currently disabled"
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Error processing award data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noResultsFound:
            return "No award availability found"
        case .rateLimitExceeded:
            return "Award search limit exceeded. Please try again later."
        case .unauthorized:
            return "Award search authentication failed"
        case .serverError(let code):
            return "Award search server error (\(code)). Please try again later."
        }
    }
}

class SeatsAeroAPIService {
    static let shared = SeatsAeroAPIService()
    private let baseURL = "https://seats.aero/partnerapi"

    private var apiKey: String {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "SEATS_AERO_API_KEY") as? String {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        print("⚠️ No Seats.aero API key found in Info.plist")
        return ""
    }

    /// Search for award availability between airports
    /// - Parameters:
    ///   - origin: Origin airport code (IATA)
    ///   - destination: Destination airport code (IATA)
    ///   - startDate: Optional start date for search range
    ///   - endDate: Optional end date for search range
    ///   - cabins: Optional cabin classes to filter (e.g., "business,first")
    ///   - sources: Optional mileage programs to filter
    /// - Returns: Array of award availability results
    func searchAwards(
        origin: String,
        destination: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        cabins: String? = nil,
        sources: String? = nil
    ) async throws -> SeatsAeroSearchResponse {
        // Check feature flag
        guard FeatureFlags.shared.canUseSeatsAero else {
            throw SeatsAeroAPIError.featureDisabled
        }

        // Construct URL
        guard var urlComponents = URLComponents(string: "\(baseURL)/search") else {
            throw SeatsAeroAPIError.invalidURL
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var queryItems = [
            URLQueryItem(name: "origin_airport", value: origin.uppercased()),
            URLQueryItem(name: "destination_airport", value: destination.uppercased())
        ]

        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
        }

        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
        }

        if let cabins = cabins {
            queryItems.append(URLQueryItem(name: "cabins", value: cabins))
        }

        if let sources = sources {
            queryItems.append(URLQueryItem(name: "sources", value: sources))
        }

        // Default to all cabin classes if not specified, take top 100 results
        if cabins == nil {
            queryItems.append(URLQueryItem(name: "cabins", value: "economy,premium,business,first"))
        }
        queryItems.append(URLQueryItem(name: "take", value: "100"))
        queryItems.append(URLQueryItem(name: "order_by", value: "lowest_mileage"))

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw SeatsAeroAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Partner-Authorization")

        print("🎫 [SEATS.AERO] Fetching award availability: \(origin) → \(destination)")
        print("🔗 [SEATS.AERO] Request URL: \(url.absoluteString)")
        print("🔑 [SEATS.AERO] API Key present: \(!apiKey.isEmpty)")

        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                print("❌ [SEATS.AERO] Invalid response type")
                throw SeatsAeroAPIError.invalidResponse
            }

            print("📡 [SEATS.AERO] Response Status: \(httpResponse.statusCode)")

            // Handle error responses
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to decode error message from response
                if let errorString = String(data: data, encoding: .utf8) {
                    print("📄 [SEATS.AERO] Error response body: \(errorString)")
                }

                switch httpResponse.statusCode {
                case 401:
                    print("❌ [SEATS.AERO] Authentication failed (401)")
                    throw SeatsAeroAPIError.unauthorized
                case 429:
                    print("⚠️ [SEATS.AERO] Rate limit exceeded (429)")
                    throw SeatsAeroAPIError.rateLimitExceeded
                case 400:
                    print("ℹ️ [SEATS.AERO] No results found (400)")
                    throw SeatsAeroAPIError.noResultsFound
                default:
                    print("❌ [SEATS.AERO] Server error (\(httpResponse.statusCode))")
                    throw SeatsAeroAPIError.serverError(httpResponse.statusCode)
                }
            }

            let decoder = JSONDecoder()
            let response = try decoder.decode(SeatsAeroSearchResponse.self, from: data)

            print("✅ [SEATS.AERO] Successfully decoded \(response.data.count) award options")

            return response
        } catch let error as SeatsAeroAPIError {
            throw error
        } catch {
            throw SeatsAeroAPIError.networkError(error)
        }
    }
}

// MARK: - Response Models

struct SeatsAeroSearchResponse: Codable {
    let data: [AwardAvailability]
    let count: Int
    let hasMore: Bool
    let cursor: Int?

    enum CodingKeys: String, CodingKey {
        case data, count, hasMore, cursor
    }
}

struct AwardAvailability: Codable, Identifiable {
    let id: String
    let routeID: String
    let date: String
    let source: String

    /// Friendly mileage program name derived from source
    var programName: String {
        MileageProgramService.shared.getProgramName(from: source)
    }

    // Economy availability
    let yAvailable: Bool?
    let yMileageCost: String?
    let yRemainingSeats: Int?

    // Premium Economy availability
    let wAvailable: Bool?
    let wMileageCost: String?
    let wRemainingSeats: Int?

    // Business availability
    let jAvailable: Bool?
    let jMileageCost: String?
    let jRemainingSeats: Int?

    // First Class availability
    let fAvailable: Bool?
    let fMileageCost: String?
    let fRemainingSeats: Int?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case routeID = "RouteID"
        case date = "Date"
        case source = "Source"
        case yAvailable = "YAvailable"
        case yMileageCost = "YMileageCost"
        case yRemainingSeats = "YRemainingSeats"
        case wAvailable = "WAvailable"
        case wMileageCost = "WMileageCost"
        case wRemainingSeats = "WRemainingSeats"
        case jAvailable = "JAvailable"
        case jMileageCost = "JMileageCost"
        case jRemainingSeats = "JRemainingSeats"
        case fAvailable = "FAvailable"
        case fMileageCost = "FMileageCost"
        case fRemainingSeats = "FRemainingSeats"
    }

    /// Get best available cabin class
    func bestAvailableCabin() -> (cabin: String, cost: String, seats: Int)? {
        if let fAvailable = fAvailable, fAvailable, let cost = fMileageCost, let seats = fRemainingSeats {
            return ("First", cost, seats)
        }
        if let jAvailable = jAvailable, jAvailable, let cost = jMileageCost, let seats = jRemainingSeats {
            return ("Business", cost, seats)
        }
        if let wAvailable = wAvailable, wAvailable, let cost = wMileageCost, let seats = wRemainingSeats {
            return ("Premium Economy", cost, seats)
        }
        if let yAvailable = yAvailable, yAvailable, let cost = yMileageCost, let seats = yRemainingSeats {
            return ("Economy", cost, seats)
        }
        return nil
    }

    /// Get all available cabins with details
    func allAvailableCabins() -> [(cabin: CabinClass, cost: String, seats: Int)] {
        var cabins: [(cabin: CabinClass, cost: String, seats: Int)] = []

        if let fAvailable = fAvailable, fAvailable, let cost = fMileageCost, let seats = fRemainingSeats {
            cabins.append((CabinClass.first, cost, seats))
        }
        if let jAvailable = jAvailable, jAvailable, let cost = jMileageCost, let seats = jRemainingSeats {
            cabins.append((CabinClass.business, cost, seats))
        }
        if let wAvailable = wAvailable, wAvailable, let cost = wMileageCost, let seats = wRemainingSeats {
            cabins.append((CabinClass.premiumEconomy, cost, seats))
        }
        if let yAvailable = yAvailable, yAvailable, let cost = yMileageCost, let seats = yRemainingSeats {
            cabins.append((CabinClass.economy, cost, seats))
        }

        return cabins
    }

    /// Check if a specific cabin is available
    func isCabinAvailable(_ cabin: CabinClass) -> Bool {
        switch cabin {
        case .first:
            return fAvailable == true
        case .business:
            return jAvailable == true
        case .premiumEconomy:
            return wAvailable == true
        case .economy:
            return yAvailable == true
        }
    }

    /// Get mileage cost for specific cabin
    func getMileageCost(for cabin: CabinClass) -> String? {
        let rawCost: String?
        switch cabin {
        case .first:
            rawCost = fMileageCost
        case .business:
            rawCost = jMileageCost
        case .premiumEconomy:
            rawCost = wMileageCost
        case .economy:
            rawCost = yMileageCost
        }
        return rawCost?.formattedMileageCost()
    }

    /// Get remaining seats for specific cabin
    func getRemainingSeats(for cabin: CabinClass) -> Int? {
        switch cabin {
        case .first:
            return fRemainingSeats
        case .business:
            return jRemainingSeats
        case .premiumEconomy:
            return wRemainingSeats
        case .economy:
            return yRemainingSeats
        }
    }

    /// Parse date from string format
    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    /// Calculate value score for smart recommendations
    /// Higher score = better value (considers cabin quality, availability, cost)
    func valueScore() -> Double {
        guard let best = bestAvailableCabin() else { return 0 }

        // Parse mileage cost (remove commas and convert to int)
        let costString = best.cost.replacingOccurrences(of: ",", with: "")
        guard let cost = Double(costString), cost > 0 else { return 0 }

        // Cabin quality multiplier
        let cabinMultiplier: Double
        switch best.cabin {
        case "First": cabinMultiplier = 4.0
        case "Business": cabinMultiplier = 3.0
        case "Premium Economy": cabinMultiplier = 2.0
        case "Economy": cabinMultiplier = 1.0
        default: cabinMultiplier = 1.0
        }

        // Availability multiplier (more seats = better)
        let availabilityMultiplier = min(Double(best.seats) / 4.0, 2.0)

        // Value score: (cabin quality × availability) / cost
        // Lower cost and higher cabin/availability = higher score
        return (cabinMultiplier * availabilityMultiplier * 100000) / cost
    }

    /// Generate booking URL for this award
    func generateBookingURL(origin: String, destination: String) -> URL? {
        guard let date = parsedDate,
              let airlineCode = AwardBookingService.shared.extractAirlineCode(from: source),
              let best = bestAvailableCabin() else {
            return nil
        }

        let cabin: CabinClass
        switch best.cabin {
        case "First": cabin = .first
        case "Business": cabin = .business
        case "Premium Economy": cabin = .premiumEconomy
        case "Economy": cabin = .economy
        default: cabin = .economy
        }

        return AwardBookingService.shared.generateBookingURL(
            airline: airlineCode,
            origin: origin,
            destination: destination,
            date: date,
            cabinClass: cabin
        )
    }
}
