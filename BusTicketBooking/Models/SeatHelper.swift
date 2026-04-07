//
//  SeatHelper.swift
//  BusTicketBooking
//
//  Created by macos on 30/3/26.
//

import Foundation

struct SeatHelper {
    /// Convert seat index (0-39 in a 10x4 matrix) to seat label (A1, A2, A3, A4, B1, B2, etc.)
    static func indexToLabel(_ index: Int) -> String {
        let row = index / 4  // Row 0-9
        let col = index % 4  // Column 0-3
        let letter = String(Character(UnicodeScalar(65 + row)!)) // A-J
        return "\(letter)\(col + 1)" // A1-A4, B1-B4, etc.
    }
    
    /// Convert seat label (A1, A2, etc.) to seat index (0-39)
    static func labelToIndex(_ label: String) -> Int? {
        guard label.count == 2 else { return nil }
        let letterChar = label.first!
        guard let colStr = label.last, let col = Int(String(colStr)) else { return nil }
        
        let row = Int(letterChar.asciiValue! - 65) // A=0, B=1, etc.
        let column = col - 1 // 1-indexed to 0-indexed
        
        guard row >= 0 && row < 10 && column >= 0 && column < 4 else { return nil }
        
        return row * 4 + column
    }
    
    /// Check if a seat is booked from the seat matrix
    static func isSeatBooked(_ index: Int, in seatMatrix: String) -> Bool {
        guard index >= 0 && index < 40 && index < seatMatrix.count else { return false }
        let idx = seatMatrix.index(seatMatrix.startIndex, offsetBy: index)
        return seatMatrix[idx] == "1"
    }
    
    /// Update the seat matrix when seats are booked
    static func updateSeatMatrix(_ matrix: String, bookingIndices: [Int]) -> String {
        var updatedMatrix = Array(matrix)
        for index in bookingIndices {
            if index >= 0 && index < updatedMatrix.count {
                updatedMatrix[index] = "1"
            }
        }
        return String(updatedMatrix)
    }
    
    /// Get all booked seat indices from matrix
    static func getBookedSeatIndices(from seatMatrix: String) -> [Int] {
        var bookedIndices: [Int] = []
        for (index, char) in seatMatrix.enumerated() {
            if char == "1" {
                bookedIndices.append(index)
            }
        }
        return bookedIndices
    }
    
    /// Get all available seat indices from matrix
    static func getAvailableSeatIndices(from seatMatrix: String) -> [Int] {
        var availableIndices: [Int] = []
        for (index, char) in seatMatrix.enumerated() {
            if char == "0" {
                availableIndices.append(index)
            }
        }
        return availableIndices
    }

    /// Count available seats from a matrix string
    static func countAvailableSeats(in seatMatrix: String) -> Int {
        return seatMatrix.filter { $0 == "0" }.count
    }
}
