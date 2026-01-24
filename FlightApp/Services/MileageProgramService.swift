//
//  MileageProgramService.swift
//  FlightApp
//
//  Service to map Seats.aero mileage program codes to friendly names
//

import Foundation

/// Information about a mileage program
struct MileageProgramInfo {
    let name: String
    let iataCode: String

    /// Returns the image name for the airline (IATA code in uppercase to match logo files)
    var imageName: String {
        return iataCode.uppercased()
    }
}

class MileageProgramService {
    static let shared = MileageProgramService()

    private init() {}

    /// Get friendly mileage program name from Seats.aero source code
    /// - Parameter source: Source identifier from Seats.aero API (e.g., "eurobonus", "lifemiles")
    /// - Returns: Friendly program name (e.g., "SAS EuroBonus", "Avianca LifeMiles")
    func getProgramName(from source: String) -> String {
        let lowerSource = source.lowercased()
        return programs[lowerSource]?.name ?? source.capitalized
    }

    /// Get complete program information including name and IATA code
    /// - Parameter source: Source identifier from Seats.aero API
    /// - Returns: MileageProgramInfo with name and IATA code, or nil if not found
    func getProgramInfo(from source: String) -> MileageProgramInfo? {
        return programs[source.lowercased()]
    }

    /// Get IATA code for a mileage program
    /// - Parameter source: Source identifier from Seats.aero API
    /// - Returns: Two-letter IATA code, or nil if not found
    func getIATACode(from source: String) -> String? {
        return programs[source.lowercased()]?.iataCode
    }

    /// Get image name for a mileage program
    /// - Parameter source: Source identifier from Seats.aero API
    /// - Returns: Image name (lowercase IATA code), or nil if not found
    func getImageName(from source: String) -> String? {
        return programs[source.lowercased()]?.imageName
    }

    /// Check if a program source exists in the mapping
    func hasProgram(_ source: String) -> Bool {
        return programs[source.lowercased()] != nil
    }

    // MARK: - Mileage Program Mapping

    /// Comprehensive mapping of Seats.aero source codes to program information
    private let programs: [String: MileageProgramInfo] = [
        // Star Alliance Programs
        "aeroplan": MileageProgramInfo(name: "Air Canada Aeroplan", iataCode: "AC"),
        "aircanada": MileageProgramInfo(name: "Air Canada Aeroplan", iataCode: "AC"),
        "united": MileageProgramInfo(name: "United MileagePlus", iataCode: "UA"),
        "lufthansa": MileageProgramInfo(name: "Lufthansa Miles & More", iataCode: "LH"),
        "singapore": MileageProgramInfo(name: "Singapore KrisFlyer", iataCode: "SQ"),
        "ana": MileageProgramInfo(name: "ANA Mileage Club", iataCode: "NH"),
        "turkish": MileageProgramInfo(name: "Turkish Miles & Smiles", iataCode: "TK"),
        "ethiopian": MileageProgramInfo(name: "Ethiopian ShebaMiles", iataCode: "ET"),
        "avianca": MileageProgramInfo(name: "Avianca LifeMiles", iataCode: "AV"),
        "lifemiles": MileageProgramInfo(name: "Avianca LifeMiles", iataCode: "AV"),
        "asiana": MileageProgramInfo(name: "Asiana Club", iataCode: "OZ"),
        "austrian": MileageProgramInfo(name: "Austrian Miles & More", iataCode: "OS"),
        "brussels": MileageProgramInfo(name: "Brussels Miles & More", iataCode: "SN"),
        "copa": MileageProgramInfo(name: "Copa ConnectMiles", iataCode: "CM"),
        "connectmiles": MileageProgramInfo(name: "Copa ConnectMiles", iataCode: "CM"),
        "egyptair": MileageProgramInfo(name: "EgyptAir Plus", iataCode: "MS"),
        "eva": MileageProgramInfo(name: "EVA Infinity MileageLands", iataCode: "BR"),
        "lot": MileageProgramInfo(name: "LOT Miles & More", iataCode: "LO"),
        "scandinavian": MileageProgramInfo(name: "SAS EuroBonus", iataCode: "SK"),
        "eurobonus": MileageProgramInfo(name: "SAS EuroBonus", iataCode: "SK"),
        "sas": MileageProgramInfo(name: "SAS EuroBonus", iataCode: "SK"),
        "shenzhen": MileageProgramInfo(name: "Shenzhen ffp", iataCode: "ZH"),
        "swiss": MileageProgramInfo(name: "Swiss Miles & More", iataCode: "LX"),
        "tap": MileageProgramInfo(name: "TAP Miles&Go", iataCode: "TP"),
        "thai": MileageProgramInfo(name: "Royal Orchid Plus", iataCode: "TG"),
        "airchina": MileageProgramInfo(name: "Air China PhoenixMiles", iataCode: "CA"),
        "airindia": MileageProgramInfo(name: "Air India Flying Returns", iataCode: "AI"),
        "airnewaealand": MileageProgramInfo(name: "Air New Zealand Airpoints", iataCode: "NZ"),

        // SkyTeam Programs
        "delta": MileageProgramInfo(name: "Delta SkyMiles", iataCode: "DL"),
        "flyingblue": MileageProgramInfo(name: "Air France-KLM Flying Blue", iataCode: "AF"),
        "airfrance": MileageProgramInfo(name: "Air France-KLM Flying Blue", iataCode: "AF"),
        "klm": MileageProgramInfo(name: "Air France-KLM Flying Blue", iataCode: "KL"),
        "aeromexico": MileageProgramInfo(name: "Aeromexico Club Premier", iataCode: "AM"),
        "virgin": MileageProgramInfo(name: "Virgin Atlantic Flying Club", iataCode: "VS"),
        "virginatlantic": MileageProgramInfo(name: "Virgin Atlantic Flying Club", iataCode: "VS"),
        "korean": MileageProgramInfo(name: "Korean Air SKYPASS", iataCode: "KE"),
        "skypass": MileageProgramInfo(name: "Korean Air SKYPASS", iataCode: "KE"),
        "alitalia": MileageProgramInfo(name: "ITA Airways Volare", iataCode: "AZ"),
        "chinasouthern": MileageProgramInfo(name: "China Southern Sky Pearl Club", iataCode: "CZ"),
        "chinaeastern": MileageProgramInfo(name: "China Eastern Eastern Miles", iataCode: "MU"),
        "aerolinas": MileageProgramInfo(name: "Aerolíneas Plus", iataCode: "AR"),
        "aeroflot": MileageProgramInfo(name: "Aeroflot Bonus", iataCode: "SU"),
        "czech": MileageProgramInfo(name: "Czech Airlines OK Plus", iataCode: "OK"),
        "garuda": MileageProgramInfo(name: "Garuda Miles", iataCode: "GA"),
        "kenya": MileageProgramInfo(name: "Kenya Airways Flying Blue", iataCode: "KQ"),
        "middle": MileageProgramInfo(name: "Middle East Airlines Cedar Miles", iataCode: "ME"),
        "saudia": MileageProgramInfo(name: "Saudia Alfursan", iataCode: "SV"),
        "tarom": MileageProgramInfo(name: "TAROM Smart Miles", iataCode: "RO"),
        "vietnam": MileageProgramInfo(name: "Vietnam Airlines Lotusmiles", iataCode: "VN"),
        "xiamen": MileageProgramInfo(name: "Xiamen Egret Club", iataCode: "MF"),

        // Oneworld Programs
        "american": MileageProgramInfo(name: "American AAdvantage", iataCode: "AA"),
        "aadvantage": MileageProgramInfo(name: "American AAdvantage", iataCode: "AA"),
        "britishairways": MileageProgramInfo(name: "British Airways Executive Club", iataCode: "BA"),
        "avios": MileageProgramInfo(name: "British Airways Executive Club", iataCode: "BA"),
        "qantas": MileageProgramInfo(name: "Qantas Frequent Flyer", iataCode: "QF"),
        "alaska": MileageProgramInfo(name: "Alaska Mileage Plan", iataCode: "AS"),
        "cathay": MileageProgramInfo(name: "Cathay Pacific Asia Miles", iataCode: "CX"),
        "asiamiles": MileageProgramInfo(name: "Cathay Pacific Asia Miles", iataCode: "CX"),
        "finnair": MileageProgramInfo(name: "Finnair Plus", iataCode: "AY"),
        "iberia": MileageProgramInfo(name: "Iberia Plus", iataCode: "IB"),
        "jal": MileageProgramInfo(name: "JAL Mileage Bank", iataCode: "JL"),
        "malaysia": MileageProgramInfo(name: "Malaysia Airlines Enrich", iataCode: "MH"),
        "qatar": MileageProgramInfo(name: "Qatar Privilege Club", iataCode: "QR"),
        "privilege": MileageProgramInfo(name: "Qatar Privilege Club", iataCode: "QR"),
        "royaljordanian": MileageProgramInfo(name: "Royal Jordanian Royal Plus", iataCode: "RJ"),
        "srilankan": MileageProgramInfo(name: "SriLankan FlySmiLes", iataCode: "UL"),

        // Other Major Programs
        "jetblue": MileageProgramInfo(name: "JetBlue TrueBlue", iataCode: "B6"),
        "trueblue": MileageProgramInfo(name: "JetBlue TrueBlue", iataCode: "B6"),
        "southwest": MileageProgramInfo(name: "Southwest Rapid Rewards", iataCode: "WN"),
        "rapidrewards": MileageProgramInfo(name: "Southwest Rapid Rewards", iataCode: "WN"),
        "emirates": MileageProgramInfo(name: "Emirates Skywards", iataCode: "EK"),
        "skywards": MileageProgramInfo(name: "Emirates Skywards", iataCode: "EK"),
        "etihad": MileageProgramInfo(name: "Etihad Guest", iataCode: "EY"),
        "hawaiian": MileageProgramInfo(name: "Hawaiian Miles", iataCode: "HA"),
        "velocity": MileageProgramInfo(name: "Virgin Australia Velocity", iataCode: "VA"),
        "virginaustralia": MileageProgramInfo(name: "Virgin Australia Velocity", iataCode: "VA"),
        "airasia": MileageProgramInfo(name: "AirAsia BIG", iataCode: "AK"),
        "big": MileageProgramInfo(name: "AirAsia BIG", iataCode: "AK"),

        // South American Programs
        "azul": MileageProgramInfo(name: "Azul TudoAzul", iataCode: "AD"),
        "tudoazul": MileageProgramInfo(name: "Azul TudoAzul", iataCode: "AD"),
        "smiles": MileageProgramInfo(name: "GOL Smiles", iataCode: "G3"),
        "gol": MileageProgramInfo(name: "GOL Smiles", iataCode: "G3"),
        "latam": MileageProgramInfo(name: "LATAM Pass", iataCode: "LA"),
        "latampass": MileageProgramInfo(name: "LATAM Pass", iataCode: "LA"),

        // Middle Eastern Programs
        "flyadeal": MileageProgramInfo(name: "flyadeal", iataCode: "F3"),
        "flynas": MileageProgramInfo(name: "Flynas", iataCode: "XY"),
        "gulfair": MileageProgramInfo(name: "Gulf Air Falconflyer", iataCode: "GF"),

        // Asian Programs
        "hainan": MileageProgramInfo(name: "Hainan Fortune Wings Club", iataCode: "HU"),
        "indigo": MileageProgramInfo(name: "IndiGo 6E Rewards", iataCode: "6E"),
        "vistara": MileageProgramInfo(name: "Vistara Club Vistara", iataCode: "UK"),
        "cebu": MileageProgramInfo(name: "Cebu Pacific GetGo", iataCode: "5J"),
        "scoot": MileageProgramInfo(name: "Scoot", iataCode: "TR"),

        // Other Programs
        "icelandair": MileageProgramInfo(name: "Icelandair Saga Club", iataCode: "FI"),
        "westjet": MileageProgramInfo(name: "WestJet Rewards", iataCode: "WS"),
        "porter": MileageProgramInfo(name: "VIPorter", iataCode: "PD"),
        "condor": MileageProgramInfo(name: "Condor Miles & More", iataCode: "DE"),
        "eurowings": MileageProgramInfo(name: "Eurowings Miles & More", iataCode: "EW"),
        "oman": MileageProgramInfo(name: "Oman Air Sindbad", iataCode: "WY"),
    ]
}
