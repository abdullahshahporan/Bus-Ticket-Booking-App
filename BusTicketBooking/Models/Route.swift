//
//  Route.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import Foundation

struct Route: Identifiable {
    let id: String
    let from: String
    let to: String
    let minPrice: Int

    var displayPrice: String {
        "From ৳\(minPrice)"
    }

    // MARK: - Local Initializer
    init(id: String, from: String, to: String, minPrice: Int) {
        self.id = id
        self.from = from
        self.to = to
        self.minPrice = minPrice
    }

    // MARK: - Firestore Initializer
    init?(documentID: String, data: [String: Any]) {
        guard
            let from = data["from"] as? String,
            let to = data["to"] as? String,
            let minPrice = data["minPrice"] as? Int
        else { return nil }

        self.id = documentID
        self.from = from
        self.to = to
        self.minPrice = minPrice
    }
}
