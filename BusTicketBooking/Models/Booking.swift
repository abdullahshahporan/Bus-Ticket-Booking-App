//
//  Booking.swift
//  BusTicketBooking
//
//  Created by macos on 30/3/26.
//

import Foundation

struct Booking: Identifiable {
    let id: String
    let busTrip: BusTrip
    let userId: String
    let seatIndices: [Int] // Indices in the 40-seat matrix (0-39)
    let seatLabels: [String] // Display names (A1, A2, etc.)
    let totalPrice: Int
    let bookingDate: Date
    let travelDate: Date
    let status: BookingStatus
    
    enum BookingStatus: String {
        case confirmed = "confirmed"
        case cancelled = "cancelled"
        case pending = "pending"
    }
    
    // MARK: - Firestore Initializer
    init?(documentID: String, data: [String: Any], busTrip: BusTrip) {
        guard
            let userId = data["userId"] as? String,
            let seatIndices = data["seatIndices"] as? [Int],
            let seatLabels = data["seatLabels"] as? [String],
            let totalPrice = data["totalPrice"] as? Int,
            let timestamp = data["bookingDate"] as? TimeInterval,
            let statusStr = data["status"] as? String,
            let status = BookingStatus(rawValue: statusStr)
        else { return nil }
        
        self.id = documentID
        self.busTrip = busTrip
        self.userId = userId
        self.seatIndices = seatIndices
        self.seatLabels = seatLabels
        self.totalPrice = totalPrice
        let bookingDate = Date(timeIntervalSince1970: timestamp)
        let travelTimestamp = data["travelDate"] as? TimeInterval
        let calendar = Calendar.current

        self.bookingDate = bookingDate
        if let travelTimestamp = travelTimestamp {
            let storedTravelDate = Date(timeIntervalSince1970: travelTimestamp)
            self.travelDate = calendar.startOfDay(for: storedTravelDate)
        } else {
            self.travelDate = calendar.startOfDay(for: bookingDate)
        }
        self.status = status
    }
    
    // MARK: - Initializer
    init(
        busTripId: String,
        busTrip: BusTrip,
        userId: String,
        seatIndices: [Int],
        seatLabels: [String],
        totalPrice: Int,
        travelDate: Date = Date()
    ) {
        self.id = UUID().uuidString
        self.busTrip = busTrip
        self.userId = userId
        self.seatIndices = seatIndices
        self.seatLabels = seatLabels
        self.totalPrice = totalPrice
        self.bookingDate = Date()
        self.travelDate = travelDate
        self.status = .confirmed
    }
    
    // MARK: - Firestore Dict
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "busTripId": busTrip.id,
            "seatIndices": seatIndices,
            "seatLabels": seatLabels,
            "totalPrice": totalPrice,
            "bookingDate": bookingDate.timeIntervalSince1970,
            "travelDate": travelDate.timeIntervalSince1970,
            "status": status.rawValue
        ]
    }

    // MARK: - Expiration Helpers

    var departureDateTime: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"

        guard let timeDate = formatter.date(from: busTrip.departureTime) else {
            return nil
        }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: travelDate)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = 0
        return calendar.date(from: dateComponents)
    }

    var isExpired: Bool {
        guard status != .cancelled else { return false }
        guard let departureDateTime = departureDateTime else { return false }
        return Date() >= departureDateTime
    }
}

struct BookingConfirmation: Identifiable {
    let id: String
    let userId: String
    let trip: BusTrip
    let seatIndices: [Int]
    let seatLabels: [String]
    let totalPrice: Int
    let bookingDate: Date
    let travelDate: Date

    init(
        id: String,
        userId: String,
        trip: BusTrip,
        seatIndices: [Int],
        seatLabels: [String],
        totalPrice: Int,
        bookingDate: Date,
        travelDate: Date
    ) {
        self.id = id
        self.userId = userId
        self.trip = trip
        self.seatIndices = seatIndices
        self.seatLabels = seatLabels
        self.totalPrice = totalPrice
        self.bookingDate = bookingDate
        self.travelDate = travelDate
    }

    init(from booking: Booking) {
        self.id = booking.id
        self.userId = booking.userId
        self.trip = booking.busTrip
        self.seatIndices = booking.seatIndices
        self.seatLabels = booking.seatLabels
        self.totalPrice = booking.totalPrice
        self.bookingDate = booking.bookingDate
        self.travelDate = booking.travelDate
    }
}
