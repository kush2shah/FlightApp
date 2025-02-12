//
//  RecentSearchStore.swift
//  FlightApp
//
//  Created by Kush Shah on 2/12/25.
//

import SwiftUI

struct RecentSearch: Identifiable, Codable, Hashable {
    let id: UUID
    let route: String
    let timestamp: Date
    
    init(route: String) {
        self.id = UUID()
        self.route = route
        self.timestamp = Date()
    }
}

class RecentSearchStore: ObservableObject {
    @Published var recentSearches: [RecentSearch] = []
    private let defaults = UserDefaults.standard
    private let recentSearchKey = "RecentFlightSearches"
    
    init() {
        loadRecentSearches()
    }
    
    func addSearch(_ route: String) {
        // Prevent duplicate recent searches
        if !recentSearches.contains(where: { $0.route.lowercased() == route.lowercased() }) {
            let newSearch = RecentSearch(route: route)
            recentSearches.insert(newSearch, at: 0)
            
            // Limit to last 10 searches
            if recentSearches.count > 10 {
                recentSearches.removeLast()
            }
            
            saveRecentSearches()
        }
    }
    
    private func saveRecentSearches() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(recentSearches) {
            defaults.set(encoded, forKey: recentSearchKey)
        }
    }
    
    private func loadRecentSearches() {
        guard let savedSearches = defaults.object(forKey: recentSearchKey) as? Data else {
            return
        }
        
        let decoder = JSONDecoder()
        if let loadedSearches = try? decoder.decode([RecentSearch].self, from: savedSearches) {
            recentSearches = loadedSearches
        }
    }
    
    func removeSearch(_ search: RecentSearch) {
        recentSearches.removeAll { $0.id == search.id }
        saveRecentSearches()
    }
}
