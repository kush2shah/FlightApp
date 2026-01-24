//
//  AirlineNameService.swift
//  FlightApp
//
//  Service to map airline IATA/ICAO codes to friendly airline names
//  Used for Amadeus API and AeroAPI responses
//

import Foundation

class AirlineNameService {
    static let shared = AirlineNameService()

    private init() {}

    /// Get friendly airline name from IATA or ICAO code
    /// - Parameter code: 2-letter IATA code or 3-letter ICAO code
    /// - Returns: Friendly airline name or the original code if not found
    func getAirlineName(from code: String) -> String {
        let upperCode = code.uppercased()
        return airlineNames[upperCode] ?? code
    }

    /// Check if an airline code exists in the mapping
    func hasAirline(_ code: String) -> Bool {
        return airlineNames[code.uppercased()] != nil
    }

    // MARK: - Airline Code to Name Dictionary

    /// Comprehensive mapping of IATA and ICAO codes to airline names
    private let airlineNames: [String: String] = [
        // Major US Carriers
        "AA": "American Airlines",
        "AAL": "American Airlines",
        "DL": "Delta Air Lines",
        "DAL": "Delta Air Lines",
        "UA": "United Airlines",
        "UAL": "United Airlines",
        "WN": "Southwest Airlines",
        "SWA": "Southwest Airlines",
        "AS": "Alaska Airlines",
        "ASA": "Alaska Airlines",
        "B6": "JetBlue Airways",
        "JBU": "JetBlue Airways",
        "NK": "Spirit Airlines",
        "NKS": "Spirit Airlines",
        "F9": "Frontier Airlines",
        "FFT": "Frontier Airlines",
        "G4": "Allegiant Air",
        "AAY": "Allegiant Air",
        "SY": "Sun Country Airlines",
        "SCX": "Sun Country Airlines",
        "HA": "Hawaiian Airlines",
        "HAL": "Hawaiian Airlines",

        // Canadian Carriers
        "AC": "Air Canada",
        "ACA": "Air Canada",
        "WS": "WestJet",
        "WJA": "WestJet",
        "PD": "Porter Airlines",
        "POE": "Porter Airlines",
        "TS": "Air Transat",
        "TSC": "Air Transat",

        // European Carriers
        "BA": "British Airways",
        "BAW": "British Airways",
        "LH": "Lufthansa",
        "DLH": "Lufthansa",
        "AF": "Air France",
        "AFR": "Air France",
        "KL": "KLM",
        "KLM": "KLM",
        "IB": "Iberia",
        "IBE": "Iberia",
        "AZ": "ITA Airways",
        "ITY": "ITA Airways",
        "LX": "Swiss",
        "SWR": "Swiss",
        "OS": "Austrian Airlines",
        "AUA": "Austrian Airlines",
        "SN": "Brussels Airlines",
        "BEL": "Brussels Airlines",
        "TP": "TAP Air Portugal",
        "TAP": "TAP Air Portugal",
        "SK": "SAS",
        "SAS": "SAS",
        "AY": "Finnair",
        "FIN": "Finnair",
        "EI": "Aer Lingus",
        "EIN": "Aer Lingus",
        "VS": "Virgin Atlantic",
        "VIR": "Virgin Atlantic",
        "FR": "Ryanair",
        "RYR": "Ryanair",
        "U2": "easyJet",
        "EZY": "easyJet",
        "VY": "Vueling",
        "VLG": "Vueling",
        "W6": "Wizz Air",
        "WZZ": "Wizz Air",
        "DE": "Condor",
        "CFG": "Condor",
        "EW": "Eurowings",
        "EWG": "Eurowings",

        // Middle Eastern Carriers
        "EK": "Emirates",
        "UAE": "Emirates",
        "QR": "Qatar Airways",
        "QTR": "Qatar Airways",
        "EY": "Etihad Airways",
        "ETD": "Etihad Airways",
        "TK": "Turkish Airlines",
        "THY": "Turkish Airlines",
        "SV": "Saudia",
        "SVA": "Saudia",
        "GF": "Gulf Air",
        "GFA": "Gulf Air",
        "MS": "EgyptAir",
        "MSR": "EgyptAir",
        "RJ": "Royal Jordanian",
        "RJA": "Royal Jordanian",
        "WY": "Oman Air",
        "OMA": "Oman Air",

        // Asian Carriers
        "SQ": "Singapore Airlines",
        "SIA": "Singapore Airlines",
        "CX": "Cathay Pacific",
        "CPA": "Cathay Pacific",
        "NH": "ANA",
        "ANA": "ANA",
        "JL": "Japan Airlines",
        "JAL": "Japan Airlines",
        "KE": "Korean Air",
        "KAL": "Korean Air",
        "OZ": "Asiana Airlines",
        "AAR": "Asiana Airlines",
        "TG": "Thai Airways",
        "THA": "Thai Airways",
        "MH": "Malaysia Airlines",
        "MAS": "Malaysia Airlines",
        "GA": "Garuda Indonesia",
        "GIA": "Garuda Indonesia",
        "PR": "Philippine Airlines",
        "PAL": "Philippine Airlines",
        "CI": "China Airlines",
        "CAL": "China Airlines",
        "BR": "EVA Air",
        "EVA": "EVA Air",
        "CA": "Air China",
        "CCA": "Air China",
        "MU": "China Eastern",
        "CES": "China Eastern",
        "CZ": "China Southern",
        "CSN": "China Southern",
        "HU": "Hainan Airlines",
        "CHH": "Hainan Airlines",
        "3U": "Sichuan Airlines",
        "CSC": "Sichuan Airlines",
        "AI": "Air India",
        "AIC": "Air India",
        "UK": "Vistara",
        "VTI": "Vistara",
        "6E": "IndiGo",
        "IGO": "IndiGo",
        "VN": "Vietnam Airlines",
        "HVN": "Vietnam Airlines",

        // Oceania Carriers
        "QF": "Qantas",
        "QFA": "Qantas",
        "VA": "Virgin Australia",
        "VOZ": "Virgin Australia",
        "JQ": "Jetstar",
        "JST": "Jetstar",
        "NZ": "Air New Zealand",
        "ANZ": "Air New Zealand",
        "FJ": "Fiji Airways",
        "FJI": "Fiji Airways",

        // Latin American Carriers
        "AM": "Aeroméxico",
        "AMX": "Aeroméxico",
        "AR": "Aerolíneas Argentinas",
        "ARG": "Aerolíneas Argentinas",
        "LA": "LATAM",
        "LAN": "LATAM",
        "CM": "Copa Airlines",
        "CMP": "Copa Airlines",
        "AV": "Avianca",
        "AVA": "Avianca",
        "G3": "GOL",
        "GLO": "GOL",
        "AD": "Azul",
        "AZU": "Azul",
        "VB": "VivaAerobus",
        "VIV": "VivaAerobus",
        "Y4": "Volaris",
        "VOI": "Volaris",

        // African Carriers
        "SA": "South African Airways",
        "SAA": "South African Airways",
        "ET": "Ethiopian Airlines",
        "ETH": "Ethiopian Airlines",
        "KQ": "Kenya Airways",
        "KQA": "Kenya Airways",
        "AT": "Royal Air Maroc",
        "RAM": "Royal Air Maroc",

        // Regional US Carriers
        "YX": "Republic Airways",
        "RPA": "Republic Airways",
        "9E": "Endeavor Air",
        "EDV": "Endeavor Air",
        "OO": "SkyWest",
        "SKW": "SkyWest",
        "OH": "PSA Airlines",
        "JIA": "PSA Airlines",
        "MQ": "Envoy Air",
        "ENY": "Envoy Air",
        "YV": "Mesa Airlines",
        "ASH": "Mesa Airlines",
        "QX": "Horizon Air",
        "QXE": "Horizon Air",

        // Cargo Carriers
        "FX": "FedEx",
        "FDX": "FedEx",
        "5X": "UPS",
        "UPS": "UPS",
    ]
}
