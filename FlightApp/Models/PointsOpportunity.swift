//
//  PointsOpportunity.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import Foundation

struct PointsOpportunity: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let pointsValue: Int
    let expirationDate: Date?
    
    init(id: UUID = UUID(), title: String, description: String, pointsValue: Int, expirationDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.pointsValue = pointsValue
        self.expirationDate = expirationDate
    }
}
