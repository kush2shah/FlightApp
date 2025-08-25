//
//  WaypointDatabaseService.swift
//  FlightApp
//
//  Created by Kush Shah on 8/20/25.
//

import Foundation
import CoreLocation

struct WaypointData {
    let identifier: String
    let coordinate: CLLocationCoordinate2D
    let type: String
    let usage: String
    let region: String
}

class WaypointDatabaseService {
    static let shared = WaypointDatabaseService()
    
    private var waypointCache: [String: WaypointData] = [:]
    private var isLoaded = false
    
    init() {
        loadWaypointData()
        loadCSVWaypoints()
    }
    
    func getWaypoint(identifier: String) -> WaypointData? {
        return waypointCache[identifier.uppercased()]
    }
    
    private func loadWaypointData() {
        // For now, let's populate with some key waypoints that commonly appear in routes
        // In production, you'd parse the ARINC 424 files
        
        let commonWaypoints = [
            // North Atlantic Common Waypoints (updated with more accurate coordinates)
            ("MERIT", 41.375837, -73.135792),  // From CIFP data
            ("TUSKY", 43.559, -67.0),          // From CIFP data
            ("ELSIR", 44.0, -63.0),
            ("MALOT", 52.0, -40.0),             // NAT waypoint
            ("GISTI", 55.0, -20.0),             // NAT waypoint
            ("LIFFY", 56.0, -15.0),             // NAT waypoint
            ("DOLAS", 50.0, 0.0),               // European waypoint
            ("LAMSO", 48.0, 5.0),               // European waypoint
            ("XETBO", 54.0, -30.0),             // North Atlantic waypoint
            ("EVRIN", 55.0, -25.0),             // North Atlantic waypoint
            ("BEXET", 52.0, -15.0),             // North Atlantic waypoint
            ("NETKI", 54.0, -10.0),             // North Atlantic waypoint
            ("DOGAL", 51.0, -35.0),             // North Atlantic waypoint
            
            // US East Coast (updated with CIFP data where available)
            ("HFD", 41.736, -72.651),           // Hartford
            ("PUT", 41.9, -70.0),               // Putnam
            ("BWZ", 39.175, -76.668),           // Baltimore
            ("SWL", 38.945, -77.454),           // Washington
            ("BETTE", 40.555543, -73.007035),   // From CIFP data
            ("ACK", 41.253, -70.060),           // Nantucket/ACK VOR
            ("KANNI", 42.633333, -67.0),        // From CIFP data
            ("BRADD", 43.15, -67.0),            // From CIFP data
            ("WITCH", 42.676640, -70.874390),   // From CIFP data
            ("ALLEX", 44.416667, -67.0),        // From CIFP data
            ("SUPRY", 44.0, -62.0),             // North Atlantic entry
            ("PORTI", 43.5, -64.0),             // North Atlantic entry
            ("JOOPY", 45.0, -60.0),             // North Atlantic entry
            ("NICSO", 46.0, -55.0),             // North Atlantic entry
            
            // US West Coast  
            ("LAX", 33.9425, -118.4081), // Los Angeles
            ("SFO", 37.6213, -122.3790), // San Francisco
            ("SEA", 47.450, -122.309),   // Seattle
            
            // European Common
            ("WAL", 52.0, -2.0),         // Wales
            ("DVR", 51.127, 1.328),      // Dover
            ("CALDA", 50.5, 1.5),        // English Channel
            ("INFEC", 52.5, -8.0),       // Irish Sea waypoint
            ("JETZI", 51.5, -5.0),       // English Channel waypoint
            ("AMFUL", 50.5, -2.0),       // English Channel waypoint
            ("CAWZE", 50.0, 0.0),        // English Channel waypoint
            ("SIRIC", 49.5, 2.0),        // European waypoint
            ("KONAN", 49.0, 5.0),        // European waypoint
            
            // Middle East / Asian Waypoints
            ("UDROS", 35.0, 45.0),       // Middle East waypoint
            ("TBN", 33.0, 48.0),         // Middle East waypoint (Mehrabad)
            ("YAVUZ", 40.0, 35.0),       // Turkish waypoint
            ("INDUR", 30.0, 60.0),       // Central Asian waypoint
            ("VETEN", 28.0, 65.0),       // Central Asian waypoint
            ("SULEL", 25.0, 68.0),       // Central Asian waypoint
            ("BODKA", 22.0, 70.0),       // Indian subcontinent waypoint
            ("MAMED", 20.0, 72.0),       // Indian subcontinent waypoint
            ("DOLOS", 18.0, 74.0),       // Indian subcontinent waypoint
            ("RUBAD", 15.0, 76.0),       // Indian subcontinent waypoint
            ("RANAH", 12.0, 78.0),       // Indian subcontinent waypoint
            ("BIROS", 10.0, 80.0),       // South Asian waypoint
            ("VIKIT", 8.0, 85.0),        // South Asian waypoint
            ("IBANI", 6.0, 90.0),        // Southeast Asian waypoint
            ("IDKUT", 4.0, 95.0),        // Southeast Asian waypoint
            ("GIVAL", 2.0, 100.0),       // Southeast Asian waypoint
            ("VPL", 3.0, 101.5),         // VOR Pulau Langkawi
            ("RINBA", 2.5, 102.0),       // Southeast Asian waypoint
            ("MAKNA", 2.0, 102.5),       // Southeast Asian waypoint
            ("TOPOR", 1.5, 103.0),       // Southeast Asian waypoint
            ("ARAMA", 1.3, 103.5),       // Singapore approach waypoint
            ("TEBUN", 1.35, 103.8),      // Singapore approach waypoint
            
            // Additional European waypoints
            ("REMBA", 48.5, 8.0),        // European waypoint
            ("MATUG", 47.0, 10.0),       // European waypoint
            ("AMASI", 45.5, 12.0),       // European waypoint
            ("BOMBI", 44.0, 14.0),       // European waypoint
            ("TENLO", 42.5, 16.0),       // European waypoint
            ("DEXIT", 41.0, 18.0),       // European waypoint
            ("PESAT", 39.5, 20.0),       // European waypoint
            ("DEGET", 38.0, 22.0),       // European waypoint
            ("LUGEB", 36.5, 24.0),       // European waypoint
            
            // Atlantic Oceanic Points (from common NAT tracks)
            ("5000N", 50.0, -50.0),      // 50N/50W
            ("5100N", 51.0, -40.0),      // 51N/40W
            ("5200N", 52.0, -30.0),      // 52N/30W
            ("5300N", 53.0, -20.0),      // 53N/20W
            ("5400N", 54.0, -10.0),      // 54N/10W
            
            // Pacific Common
            ("ALLBE", 36.0, -140.0),     // Pacific waypoint
            ("TUNEE", 40.0, -150.0),     // Pacific waypoint
        ]
        
        for (identifier, lat, lon) in commonWaypoints {
            let waypoint = WaypointData(
                identifier: identifier,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                type: "WAYPOINT",
                usage: "ENROUTE",
                region: "UNKNOWN"
            )
            waypointCache[identifier] = waypoint
        }
        
        isLoaded = true
    }
    
    // MARK: - ARINC 424 Parsing Methods
    
    /// Parse ARINC 424 waypoint line format
    /// Example: "SUSAEAENRT   26FLW K21    I D   N36442340W121282270                       E0156     NAS        B     FLW306/D126           021528110"
    func parseARINC424Waypoint(_ line: String) -> WaypointData? {
        guard line.count >= 51 else { return nil }
        
        // Extract waypoint identifier (positions 13-18)
        let identifier = String(line[line.index(line.startIndex, offsetBy: 13)..<line.index(line.startIndex, offsetBy: 18)]).trimmingCharacters(in: .whitespaces)
        
        // Extract latitude (positions 32-41)
        let latString = String(line[line.index(line.startIndex, offsetBy: 32)..<line.index(line.startIndex, offsetBy: 41)])
        
        // Extract longitude (positions 41-51)  
        let lonString = String(line[line.index(line.startIndex, offsetBy: 41)..<line.index(line.startIndex, offsetBy: 51)])
        
        // Parse coordinates
        guard let coordinate = parseARINC424Coordinate(lat: latString, lon: lonString) else {
            return nil
        }
        
        return WaypointData(
            identifier: identifier,
            coordinate: coordinate,
            type: "WAYPOINT",
            usage: "ENROUTE", 
            region: String(line[line.index(line.startIndex, offsetBy: 6)..<line.index(line.startIndex, offsetBy: 10)])
        )
    }
    
    /// Parse ARINC 424 coordinate format: "N36442340" -> 36.442340° N
    private func parseARINC424Coordinate(lat: String, lon: String) -> CLLocationCoordinate2D? {
        // Latitude format: NDDMMSSSS or SDDMMSSSS
        guard lat.count == 9, lon.count == 10 else { return nil }
        
        let latDir = lat.first!
        let latNumbers = String(lat.dropFirst())
        
        let lonDir = lon.first!
        let lonNumbers = String(lon.dropFirst())
        
        // Parse latitude: DDMMSSSS
        guard let latDegrees = Double(String(latNumbers.prefix(2))),
              let latMinutes = Double(String(latNumbers.dropFirst(2).prefix(2))),
              let latSeconds = Double(String(latNumbers.dropFirst(4))) else {
            return nil
        }
        
        // Parse longitude: DDDMMSSSS
        guard let lonDegrees = Double(String(lonNumbers.prefix(3))),
              let lonMinutes = Double(String(lonNumbers.dropFirst(3).prefix(2))),
              let lonSeconds = Double(String(lonNumbers.dropFirst(5))) else {
            return nil
        }
        
        // Convert to decimal degrees
        let latitude = latDegrees + (latMinutes / 60.0) + (latSeconds / 100.0 / 3600.0)
        let longitude = lonDegrees + (lonMinutes / 60.0) + (lonSeconds / 100.0 / 3600.0)
        
        let finalLat = latitude * (latDir == "N" ? 1 : -1)
        let finalLon = longitude * (lonDir == "E" ? 1 : -1)
        
        return CLLocationCoordinate2D(latitude: finalLat, longitude: finalLon)
    }
    
    // MARK: - Bulk Loading from ARINC 424 Files
    
    /// Load waypoint data from ARINC 424 file
    func loadFromARINC424File(at path: String) {
        guard let content = try? String(contentsOfFile: path) else {
            print("Failed to load ARINC 424 file at \(path)")
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        var loadedCount = 0
        
        for line in lines {
            if let waypoint = parseARINC424Waypoint(line) {
                waypointCache[waypoint.identifier] = waypoint
                loadedCount += 1
            }
        }
        
        print("Loaded \(loadedCount) waypoints from ARINC 424 file")
        isLoaded = true
    }
    
    /// Load waypoints from CSV file
    private func loadCSVWaypoints() {
        // Try to load the comprehensive navigation database first
        if let path = Bundle.main.path(forResource: "complete_navigation_database", ofType: "csv"),
           let content = try? String(contentsOfFile: path) {
            print("📍 Loading from comprehensive navigation database...")
            parseCSVContent(content, source: "ARINC424")
            return
        }
        
        // Fallback to bundled international waypoints
        guard let path = Bundle.main.path(forResource: "international_waypoints", ofType: "csv") else {
            print("⚠️ No waypoint database found in bundle")
            return
        }
        
        guard let content = try? String(contentsOfFile: path) else {
            print("⚠️ Failed to read international_waypoints.csv")
            return
        }
        
        parseCSVContent(content, source: "bundled")
    }
    
    private func parseCSVContent(_ content: String, source: String) {
        let lines = content.components(separatedBy: .newlines)
        var loadedCount = 0
        
        // Skip header line
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let components = line.components(separatedBy: ",")
            
            // Handle different CSV formats
            var identifier: String
            var latitude: Double
            var longitude: Double
            var type: String
            var usage: String
            var region: String
            
            if source == "ARINC424" && components.count >= 7 {
                // ARINC 424 format: identifier,latitude,longitude,type,nav_type,usage,region
                identifier = components[0].trimmingCharacters(in: .whitespaces)
                guard let lat = Double(components[1]),
                      let lon = Double(components[2]) else { continue }
                latitude = lat
                longitude = lon
                type = components[3].trimmingCharacters(in: .whitespaces)
                usage = components[5].trimmingCharacters(in: .whitespaces)
                region = components.count > 6 ? components[6].trimmingCharacters(in: .whitespaces) : ""
            } else if components.count >= 6 {
                // Bundled format: identifier,latitude,longitude,type,usage,region
                identifier = components[0].trimmingCharacters(in: .whitespaces)
                guard let lat = Double(components[1]),
                      let lon = Double(components[2]) else { continue }
                latitude = lat
                longitude = lon
                type = components[3].trimmingCharacters(in: .whitespaces)
                usage = components[4].trimmingCharacters(in: .whitespaces)
                region = components[5].trimmingCharacters(in: .whitespaces)
            } else {
                continue
            }
            
            let waypoint = WaypointData(
                identifier: identifier,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                type: type,
                usage: usage,
                region: region
            )
            
            waypointCache[identifier] = waypoint
            loadedCount += 1
        }
        
        print("📍 Loaded \(loadedCount) waypoints from \(source) database")
    }
}

// MARK: - Route Parsing Extensions

extension WaypointDatabaseService {
    
    /// Parse route using AeroAPI route data and comprehensive waypoint database
    func parseRouteFromAeroAPI(_ fixes: [RouteFix]) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var lastValidCoordinate: CLLocationCoordinate2D?
        
        for fix in fixes {
            var coordinateToAdd: CLLocationCoordinate2D?
            
            // First, try using AeroAPI coordinates if they seem valid
            if let coordinate = fix.coordinate,
               abs(coordinate.latitude) <= 90.0 && abs(coordinate.longitude) <= 180.0 {
                
                // Validate that coordinate makes geographical sense
                if let last = lastValidCoordinate {
                    let distance = distanceBetween(last, coordinate)
                    // Skip coordinates that jump too far back (likely data errors)
                    if distance > 15000 { // 15000km max - more than halfway around Earth
                        print("⚠️ Skipping \(fix.name) AeroAPI coordinate - too far: \(Int(distance))km")
                    } else {
                        coordinateToAdd = coordinate
                    }
                } else {
                    coordinateToAdd = coordinate
                }
            }
            
            // If AeroAPI coordinate not used, try waypoint database
            if coordinateToAdd == nil {
                if let waypoint = getWaypoint(identifier: fix.name) {
                    coordinateToAdd = waypoint.coordinate
                    print("📍 Resolved \(fix.name) from waypoint database: \(waypoint.coordinate)")
                } else {
                    // Skip unresolved waypoints (likely airway identifiers)
                    print("⚠️ Skipping unresolved waypoint: \(fix.name)")
                    continue
                }
            }
            
            if let coord = coordinateToAdd {
                coordinates.append(coord)
                lastValidCoordinate = coord
            }
        }
        
        print("🗺️ Parsed \(coordinates.count) valid waypoints from \(fixes.count) AeroAPI fixes")
        return coordinates
    }
    
    /// Calculate distance between two coordinates in kilometers
    private func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2) / 1000.0 // Convert to km
    }
    
    /// Determine if a segment is likely transoceanic (crossing major water bodies)
    private func isTransoceanicSegment(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Bool {
        // Atlantic crossing (Americas to Europe/Africa)
        if (start.longitude < -30 && end.longitude > -10) || (start.longitude > -10 && end.longitude < -30) {
            return true
        }
        
        // Pacific crossing (Americas to Asia/Oceania)
        if (start.longitude < -100 && end.longitude > 100) || (start.longitude > 100 && end.longitude < -100) {
            return true
        }
        
        // Large longitude difference indicates potential ocean crossing
        let longitudeDiff = abs(start.longitude - end.longitude)
        if longitudeDiff > 60 { // More than 60 degrees longitude difference
            return true
        }
        
        return false
    }
    
    /// Check if component is a speed/altitude annotation (M083F300, N0483F300)
    private func isSpeedAltitudeAnnotation(_ component: String) -> Bool {
        if component.count < 6 { return false }
        
        // Check for Mach speed (M083F300) or indicated airspeed (N0483F300)
        if (component.starts(with: "M") || component.starts(with: "N")) && component.contains("F") {
            let parts = component.dropFirst().split(separator: "F")
            return parts.count == 2 && parts.allSatisfy { $0.allSatisfy(\.isNumber) }
        }
        
        return false
    }
    
    /// Fallback: Parse a complete aviation route string using the waypoint database
    func parseRoute(_ routeString: String, origin: String, destination: String) -> [CLLocationCoordinate2D] {
        let components = routeString.components(separatedBy: " ")
        var coordinates: [CLLocationCoordinate2D] = []
        
        // Add origin airport
        if let originCoord = AirportCoordinateService.shared.getCoordinate(for: origin)?.coordinate {
            coordinates.append(originCoord)
        }
        
        for component in components {
            let cleanComponent = component.trimmingCharacters(in: .whitespaces)
            guard !cleanComponent.isEmpty else { continue }
            
            // Skip speed/altitude annotations (M083F300, N0483F300, etc.)
            if isSpeedAltitudeAnnotation(cleanComponent) { continue }
            
            // Skip "DCT" (Direct To) routing instructions
            if cleanComponent == "DCT" { continue }
            
            // First, try to parse oceanic coordinates (both 4100N/06000W and 28S142E formats)
            if let coordinate = parseOceanicCoordinate(cleanComponent) {
                coordinates.append(coordinate)
                print("📍 Parsed oceanic coordinate \(cleanComponent): \(coordinate)")
                continue
            }
            
            // If that fails, try parsing just the coordinate part (for combined formats like 28S142E/N0497F320)
            if cleanComponent.contains("/") {
                let coordinatePart = cleanComponent.components(separatedBy: "/").first ?? cleanComponent
                if coordinatePart != cleanComponent, let coordinate = parseOceanicCoordinate(coordinatePart) {
                    coordinates.append(coordinate)
                    print("📍 Parsed oceanic coordinate \(coordinatePart) from \(cleanComponent): \(coordinate)")
                    continue
                }
            }
            
            // Extract waypoint name from combined waypoint/speed (OLREL/N0483F300 -> OLREL)
            let waypointName = cleanComponent.components(separatedBy: "/").first ?? cleanComponent
            
            // Skip airway designators (UL975, M16, L603, P2, N774, H530, A576, etc.)
            if isAirwayDesignator(waypointName) { 
                print("🛤️ Skipping airway designator: \(waypointName)")
                continue 
            }
            
            // Skip NAT track references (NATV, NATW, NATU, etc.)
            if waypointName.hasPrefix("NAT") && waypointName.count == 4 { continue }
            
            // Skip organized track system references (like N97B, N357C, N271B)
            if isOrganizedTrackSystem(waypointName) { continue }
            
            // Look up waypoint in database with geographic context
            if let waypoint = getWaypoint(identifier: waypointName) {
                // Filter out waypoints that don't make geographical sense for international routes
                if !coordinates.isEmpty, let lastCoord = coordinates.last {
                    let distance = distanceBetween(lastCoord, waypoint.coordinate)
                    // Skip waypoints that require >5000km jump (likely wrong region)
                    if distance > 5000 {
                        print("⚠️ Skipping \(cleanComponent) - too far from route: \(Int(distance))km")
                        continue
                    }
                }
                coordinates.append(waypoint.coordinate)
                continue
            }
            
            // Check for airports
            if let airportCoord = AirportCoordinateService.shared.getCoordinate(for: cleanComponent)?.coordinate {
                coordinates.append(airportCoord)
                continue
            }
            
            // If we can't match the waypoint, log it for debugging
            print("⚠️ Unknown waypoint/fix: \(cleanComponent)")
        }
        
        // Add destination airport
        if let destCoord = AirportCoordinateService.shared.getCoordinate(for: destination)?.coordinate {
            coordinates.append(destCoord)
        }
        
        print("🗺️ Parsed \(coordinates.count) waypoints from route string fallback")
        return coordinates
    }
    
    private func isAirwayDesignator(_ component: String) -> Bool {
        // Match airways like UL975, M16, L603, P2, A846, B449, etc.
        let pattern = "^[A-Z]+[0-9]+[A-Z]*$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: component.count)
        return regex?.firstMatch(in: component, options: [], range: range) != nil
    }
    
    private func isOrganizedTrackSystem(_ component: String) -> Bool {
        // Match organized track systems like N97B, N357C, N271B, etc.
        let pattern = "^[A-Z][0-9]+[A-Z]$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: component.count)
        return regex?.firstMatch(in: component, options: [], range: range) != nil
    }
    
    private func parseOceanicCoordinate(_ string: String) -> CLLocationCoordinate2D? {
        // Handle format like "4100N/06000W"
        if string.contains("/") {
            let parts = string.components(separatedBy: "/")
            guard parts.count == 2 else { 
                print("⚠️ Failed to split coordinate: \(string)")
                return nil 
            }
            
            let latString = parts[0]
            let lonString = parts[1]
            
            guard let latDir = latString.last,
                  let lonDir = lonString.last,
                  ["N", "S"].contains(String(latDir)),
                  ["E", "W"].contains(String(lonDir)) else { 
                print("⚠️ Invalid direction in coordinate: \(string)")
                return nil 
            }
            
            let latNumbers = String(latString.dropLast())
            let lonNumbers = String(lonString.dropLast())
            
            guard let latValue = Double(latNumbers),
                  let lonValue = Double(lonNumbers) else { 
                print("⚠️ Failed to parse numbers in coordinate: \(string) (lat: \(latNumbers), lon: \(lonNumbers))")
                return nil 
            }
            
            // Parse latitude: DDMM format (e.g., "0649" = 06°49' = 6.816°)
            let latDegrees = latNumbers.count == 4 ? Int(latValue / 100.0) : Int(latValue)
            let latMinutes = latNumbers.count == 4 ? Int(latValue.truncatingRemainder(dividingBy: 100)) : 0
            let latitude = (Double(latDegrees) + Double(latMinutes) / 60.0) * (latDir == "N" ? 1 : -1)
            
            // Parse longitude: DDDMM or DDMM format (e.g., "08043" = 080°43' = 80.716°)
            let lonDegrees = lonNumbers.count >= 4 ? Int(lonValue / 100.0) : Int(lonValue)
            let lonMinutes = lonNumbers.count >= 4 ? Int(lonValue.truncatingRemainder(dividingBy: 100)) : 0
            let longitude = (Double(lonDegrees) + Double(lonMinutes) / 60.0) * (lonDir == "E" ? 1 : -1)
            
            print("📍 Successfully parsed \(string) → lat: \(latitude), lon: \(longitude)")
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        // Handle format like "28S142E"
        let regex = try? NSRegularExpression(pattern: #"(\d+)([NS])(\d+)([EW])"#, options: [])
        let nsRange = NSRange(string.startIndex..<string.endIndex, in: string)
        
        if let match = regex?.firstMatch(in: string, options: [], range: nsRange) {
            let latRange = Range(match.range(at: 1), in: string)!
            let latDirRange = Range(match.range(at: 2), in: string)!
            let lonRange = Range(match.range(at: 3), in: string)!
            let lonDirRange = Range(match.range(at: 4), in: string)!
            
            guard let latValue = Double(String(string[latRange])),
                  let lonValue = Double(String(string[lonRange])) else { return nil }
            
            let latDir = String(string[latDirRange])
            let lonDir = String(string[lonDirRange])
            
            // Parse latitude: DDMM format (e.g., 0649 = 06°49' = 6.816°)
            let latDegrees = Int(latValue / 100.0)
            let latMinutes = Int(latValue.truncatingRemainder(dividingBy: 100))
            let latitude = (Double(latDegrees) + Double(latMinutes) / 60.0) * (latDir == "N" ? 1 : -1)
            
            // Parse longitude: DDDMM or DDMM format (e.g., 08043 = 080°43' = 80.716°)
            let lonDegrees = Int(lonValue / 100.0)
            let lonMinutes = Int(lonValue.truncatingRemainder(dividingBy: 100))
            let longitude = (Double(lonDegrees) + Double(lonMinutes) / 60.0) * (lonDir == "E" ? 1 : -1)
            
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        return nil
    }
}