//
//  PointsBalance.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import Foundation

struct PointsBalance: Identifiable {
    let id: UUID
    let program: String
    let balance: Int
    let lastUpdated: Date
    
    init(id: UUID = UUID(), program: String, balance: Int, lastUpdated: Date = Date()) {
        self.id = id
        self.program = program
        self.balance = balance
        self.lastUpdated = lastUpdated
    }
}
