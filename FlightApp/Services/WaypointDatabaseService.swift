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
    }
    
    func getWaypoint(identifier: String) -> WaypointData? {
        return waypointCache[identifier.uppercased()]
    }
    
    private func loadWaypointData() {
        // For now, let's populate with some key waypoints that commonly appear in routes
        // In production, you'd parse the ARINC 424 files
        
        let commonWaypoints = [
            // North Atlantic Common Waypoints
            ("MERIT", 41.2, -71.8),
            ("TUSKY", 42.5, -67.0),
            ("ELSIR", 44.0, -63.0),
            ("MALOT", 52.0, -40.0),
            ("GISTI", 55.0, -20.0),
            ("LIFFY", 56.0, -15.0),
            ("DOLAS", 50.0, 0.0),
            ("LAMSO", 48.0, 5.0),
            
            // US East Coast
            ("HFD", 41.736, -72.651),    // Hartford
            ("PUT", 41.9, -70.0),        // Putnam
            ("BWZ", 39.175, -76.668),    // Baltimore
            ("SWL", 38.945, -77.454),    // Washington
            
            // US West Coast  
            ("LAX", 33.9425, -118.4081), // Los Angeles
            ("SFO", 37.6213, -122.3790), // San Francisco
            ("SEA", 47.450, -122.309),   // Seattle
            
            // European Common
            ("WAL", 52.0, -2.0),         // Wales
            ("DVR", 51.127, 1.328),      // Dover
            ("CALDA", 50.5, 1.5),        // English Channel
            
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
}

// MARK: - Route Parsing Extensions

extension WaypointDatabaseService {
    
    /// Parse route using AeroAPI route data (preferred method)
    func parseRouteFromAeroAPI(_ fixes: [RouteFix]) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        
        for fix in fixes {
            if let coordinate = fix.coordinate {
                coordinates.append(coordinate)
            }
        }
        
        print("🗺️ Parsed \(coordinates.count) waypoints from AeroAPI route data")
        return coordinates
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
            
            // Skip airway designators (UL975, M16, etc.)
            if isAirwayDesignator(cleanComponent) { continue }
            
            // Skip NAT references
            if cleanComponent.hasPrefix("NATW") || cleanComponent == "NATW" { continue }
            
            // Parse oceanic coordinates (5000N/05000W format)
            if let coordinate = parseOceanicCoordinate(cleanComponent) {
                coordinates.append(coordinate)
                continue
            }
            
            // Look up waypoint in database
            if let waypoint = getWaypoint(identifier: cleanComponent) {
                coordinates.append(waypoint.coordinate)
                continue
            }
            
            // Check for airports
            if let airportCoord = AirportCoordinateService.shared.getCoordinate(for: cleanComponent)?.coordinate {
                coordinates.append(airportCoord)
            }
        }
        
        // Add destination airport
        if let destCoord = AirportCoordinateService.shared.getCoordinate(for: destination)?.coordinate {
            coordinates.append(destCoord)
        }
        
        print("🗺️ Parsed \(coordinates.count) waypoints from route string fallback")
        return coordinates
    }
    
    private func isAirwayDesignator(_ component: String) -> Bool {
        let pattern = "^[A-Z]+[0-9]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: component.count)
        return regex?.firstMatch(in: component, options: [], range: range) != nil
    }
    
    private func parseOceanicCoordinate(_ string: String) -> CLLocationCoordinate2D? {
        let parts = string.components(separatedBy: "/")
        guard parts.count == 2 else { return nil }
        
        let latString = parts[0]
        let lonString = parts[1]
        
        // Handle formats like "5000N/05000W"
        guard let latDir = latString.last,
              let lonDir = lonString.last,
              ["N", "S"].contains(String(latDir)),
              ["E", "W"].contains(String(lonDir)) else { return nil }
        
        let latNumbers = String(latString.dropLast())
        let lonNumbers = String(lonString.dropLast())
        
        guard let latValue = Double(latNumbers),
              let lonValue = Double(lonNumbers) else { return nil }
        
        let latitude = (latNumbers.count == 4 ? latValue / 100.0 : latValue) * (latDir == "N" ? 1 : -1)
        let longitude = (lonNumbers.count == 5 ? lonValue / 100.0 : lonValue) * (lonDir == "E" ? 1 : -1)
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}