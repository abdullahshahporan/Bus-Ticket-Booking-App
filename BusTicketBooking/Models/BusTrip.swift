//
//  BusTrip.swift
//  BusTicketBooking
//
//  Created by macos on 4/3/26.
//

import Foundation

struct BusTrip: Identifiable {
    let id: String
    let busName: String
    let source: String
    let destination: String
    let departureTime: String
    let arrivalTime: String
    var availableSeats: Int
    let ticketPrice: Int
    let discount: Int
    let busType: String
    var seatMatrix: String // 40-character binary string: 0 = available, 1 = booked
    let pickupPoints: [String]
    let droppingPoints: [String]

    // MARK: - Firestore Initializer
    init?(documentID: String, data: [String: Any]) {
        guard
            let busName = data["busName"] as? String,
            let source = data["source"] as? String,
            let destination = data["destination"] as? String,
            let departureTime = data["departureTime"] as? String,
            let arrivalTime = data["arrivalTime"] as? String,
            let availableSeats = data["availableSeats"] as? Int,
            let ticketPrice = data["ticketPrice"] as? Int,
            let busType = data["busType"] as? String
        else { return nil }

        self.id = documentID
        self.busName = busName
        self.source = source
        self.destination = destination
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.availableSeats = availableSeats
        self.ticketPrice = ticketPrice
        self.discount = min(max(data["discount"] as? Int ?? 0, 0), 100)
        self.busType = busType
        self.pickupPoints = data["pickupPoints"] as? [String] ?? []
        self.droppingPoints = data["droppingPoints"] as? [String] ?? []
        let rawMatrix = data["seatMatrix"]
        let seatMatrixString: String
        if let matrixString = rawMatrix as? String {
            seatMatrixString = matrixString
        } else if let matrixArray = rawMatrix as? [Int] {
            seatMatrixString = matrixArray.map { $0 == 1 ? "1" : "0" }.joined()
        } else if let matrixArray = rawMatrix as? [NSNumber] {
            seatMatrixString = matrixArray.map { $0.intValue == 1 ? "1" : "0" }.joined()
        } else if let matrixArray = rawMatrix as? [Any] {
            seatMatrixString = matrixArray.compactMap { ($0 as? NSNumber)?.intValue }.map {
                $0 == 1 ? "1" : "0"
            }.joined()
        } else {
            seatMatrixString = String(repeating: "0", count: 40)
        }

        self.seatMatrix = seatMatrixString
        if seatMatrixString.count == 40 {
            self.availableSeats = SeatHelper.countAvailableSeats(in: seatMatrixString)
        }
    }

    // MARK: - Computed Properties
    var duration: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"
        guard let dep = formatter.date(from: departureTime),
              let arr = formatter.date(from: arrivalTime) else {
            return "--"
        }
        var diff = arr.timeIntervalSince(dep)
        if diff < 0 { diff += 24 * 3600 } // overnight trip
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    var priceFormatted: String {
        "৳\(ticketPrice)"
    }

    var discountedPrice: Int {
        guard discount > 0 else { return ticketPrice }
        return max(ticketPrice - (ticketPrice * discount / 100), 0)
    }

    var discountedPriceFormatted: String {
        "৳\(discountedPrice)"
    }

    var hasDiscount: Bool {
        discount > 0
    }
}
