//
//  BookingViewModel.swift
//  BusTicketBooking
//
//  Created by macos on 30/3/26.
//

import Foundation
import FirebaseFirestore

@MainActor
class BookingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bookings: [Booking] = []
    
    private let db = Firestore.firestore()
    
    // MARK: - Booking Management
    
    /// Book seats for a bus trip
    func bookSeats(
        _ seatIndices: [Int],
        for trip: BusTrip,
        userId: String,
        totalPrice: Int,
        travelDate: Date
    ) async -> BookingConfirmation? {
        isLoading = true
        errorMessage = nil
        
        do {
            // Update seat matrix in busTrips
            let seatLabels = seatIndices.map { SeatHelper.indexToLabel($0) }
            let updatedMatrix = SeatHelper.updateSeatMatrix(trip.seatMatrix, bookingIndices: seatIndices)
            
            // Create booking record
            let bookingDate = Date()
            let normalizedTravelDate = Calendar.current.startOfDay(for: travelDate)
            var bookingData: [String: Any] = [
                "userId": userId,
                "busTripId": trip.id,
                "seatIndices": seatIndices,
                "seatLabels": seatLabels,
                "totalPrice": totalPrice,
                "bookingDate": bookingDate.timeIntervalSince1970,
                "travelDate": normalizedTravelDate.timeIntervalSince1970,
                "status": "confirmed"
            ]

            if let operatorId = trip.operatorId {
                bookingData["operatorId"] = operatorId
            }

            if let operatorEmail = trip.operatorEmail {
                bookingData["operatorEmail"] = operatorEmail
            }

            if let operatorName = trip.operatorName {
                bookingData["operatorName"] = operatorName
            }
            
            // Use a batch write to ensure atomicity
            let batch = db.batch()
            
            let availableSeats = SeatHelper.countAvailableSeats(in: updatedMatrix)

            // Update busTrip seatMatrix
            let busRef = db.collection("busTrips").document(trip.id)
            batch.updateData([
                "seatMatrix": updatedMatrix,
                "availableSeats": availableSeats
            ], forDocument: busRef)
            
            // Create booking document
            let bookingRef = db.collection("bookings").document()
            batch.setData(bookingData, forDocument: bookingRef)
            
            try await batch.commit()
            isLoading = false
            return BookingConfirmation(
                id: bookingRef.documentID,
                userId: userId,
                trip: trip,
                seatIndices: seatIndices,
                seatLabels: seatLabels,
                totalPrice: totalPrice,
                bookingDate: bookingDate,
                travelDate: normalizedTravelDate
            )
            
        } catch {
            errorMessage = "Failed to book seats: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    /// Fetch bookings for a user
    func fetchUserBookings(userId: String) {
        isLoading = true
        errorMessage = nil

        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                self.bookings = try await self.fetchUserBookingsWithFallback(userId: userId)
            } catch {
                self.errorMessage = self.firestoreErrorMessage(
                    error,
                    fallbackPrefix: "Unable to load bookings"
                )
            }

            self.isLoading = false
        }
    }
    
    /// Fetch all bookings for a specific bus trip
    func fetchTripBookings(tripId: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("busTripId", isEqualTo: tripId)
            .getDocuments()

        var tripBookings: [Booking] = []

        for document in snapshot.documents {
            let data = document.data()

            guard let busTripId = data["busTripId"] as? String else {
                continue
            }

            let tripSnapshot = try await db.collection("busTrips")
                .document(busTripId)
                .getDocument()

            guard
                let tripData = tripSnapshot.data(),
                let trip = BusTrip(documentID: tripSnapshot.documentID, data: tripData),
                let booking = Booking(documentID: document.documentID, data: data, busTrip: trip)
            else {
                continue
            }

            tripBookings.append(booking)
        }

        return tripBookings
    }

    
    /// Cancel a booking
    func cancelBooking(_ booking: Booking) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Update booking status
            try await db.collection("bookings").document(booking.id)
                .updateData(["status": "cancelled"])
            
            // Update seat matrix by removing booked seats
            let currentTrip = booking.busTrip
            var updatedMatrix = Array(currentTrip.seatMatrix)
            for index in booking.seatIndices {
                if index >= 0 && index < updatedMatrix.count {
                    updatedMatrix[index] = "0"
                }
            }
            
            let updatedMatrixString = String(updatedMatrix)
            let availableSeats = SeatHelper.countAvailableSeats(in: updatedMatrixString)

            try await db.collection("busTrips").document(currentTrip.id)
                .updateData([
                    "seatMatrix": updatedMatrixString,
                    "availableSeats": availableSeats
                ])
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to cancel booking: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    private func firestoreErrorMessage(_ error: Error, fallbackPrefix: String) -> String {
        let nsError = error as NSError
        let missingIndexCode = FirestoreErrorCode.failedPrecondition.rawValue
        let permissionCode = FirestoreErrorCode.permissionDenied.rawValue

        if nsError.domain == FirestoreErrorDomain, nsError.code == missingIndexCode {
            return "\(fallbackPrefix): Firestore index is missing. Create the suggested composite index for faster server-side sorting."
        }

        if nsError.domain == FirestoreErrorDomain, nsError.code == permissionCode {
            return "\(fallbackPrefix): Missing or insufficient permissions. Please update Firestore rules for bookings and busTrips read access."
        }

        return "\(fallbackPrefix): \(error.localizedDescription)"
    }

    private func fetchUserBookingsWithFallback(userId: String) async throws -> [Booking] {
        do {
            return try await fetchUserBookingsQuery(userId: userId, ordered: true)
        } catch {
            if isMissingIndexError(error) {
                // Fallback to non-indexed query and sort locally so UI still works.
                return try await fetchUserBookingsQuery(userId: userId, ordered: false)
            }
            throw error
        }
    }

    private func fetchUserBookingsQuery(userId: String, ordered: Bool) async throws -> [Booking] {
        var query: Query = db.collection("bookings")
            .whereField("userId", isEqualTo: userId)

        if ordered {
            query = query.order(by: "bookingDate", descending: true)
        }

        let snapshot = try await query.getDocuments()
        var fetchedBookings: [Booking] = []

        for document in snapshot.documents {
            let data = document.data()

            guard let busTripId = data["busTripId"] as? String else {
                continue
            }

            let tripSnapshot = try await db.collection("busTrips")
                .document(busTripId)
                .getDocument()

            guard
                let tripData = tripSnapshot.data(),
                let trip = BusTrip(documentID: tripSnapshot.documentID, data: tripData),
                let booking = Booking(documentID: document.documentID, data: data, busTrip: trip)
            else {
                continue
            }

            fetchedBookings.append(booking)
        }

        if !ordered {
            fetchedBookings.sort { $0.bookingDate > $1.bookingDate }
        }

        return fetchedBookings
    }

    private func isMissingIndexError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == FirestoreErrorDomain
            && nsError.code == FirestoreErrorCode.failedPrecondition.rawValue
    }
}
