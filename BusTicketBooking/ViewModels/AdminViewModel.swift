//
//  AdminViewModel.swift
//  BusTicketBooking
//

import Foundation
import FirebaseFirestore

@MainActor
class AdminViewModel: ObservableObject {
    @Published var busTrips: [BusTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var totalBookings: Int = 0
    @Published var totalUsers: Int = 0

    private let db = Firestore.firestore()

    // MARK: - Add Bus

    func addBus(
        busName: String,
        source: String,
        destination: String,
        departureTime: String,
        arrivalTime: String,
        ticketPrice: Int,
        busType: String,
        pickupPoints: [String],
        droppingPoints: [String]
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let filteredPickup = pickupPoints.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let filteredDropping = droppingPoints.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let data: [String: Any] = [
            "busName": busName,
            "source": source,
            "destination": destination,
            "departureTime": departureTime,
            "arrivalTime": arrivalTime,
            "ticketPrice": ticketPrice,
            "busType": busType,
            "availableSeats": 40,
            "seatMatrix": String(repeating: "0", count: 40),
            "pickupPoints": filteredPickup,
            "droppingPoints": filteredDropping
        ]

        do {
            try await db.collection("busTrips").addDocument(data: data)
            successMessage = "Bus added successfully!"
            isLoading = false
            await fetchAllBuses()
            return true
        } catch {
            errorMessage = "Failed to add bus: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Fetch All Buses

    func fetchAllBuses() async {
        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try await db.collection("busTrips").getDocuments()
            busTrips = snapshot.documents.compactMap {
                BusTrip(documentID: $0.documentID, data: $0.data())
            }.sorted { $0.busName < $1.busName }
            isLoading = false
        } catch {
            errorMessage = "Failed to load buses: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Delete Bus

    func deleteBus(id: String) async -> Bool {
        do {
            try await db.collection("busTrips").document(id).delete()
            busTrips.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Fetch Stats

    func fetchStats() async {
        do {
            let bookings = try await db.collection("bookings").getDocuments()
            totalBookings = bookings.documents.count
            let users = try await db.collection("users").getDocuments()
            totalUsers = users.documents.count
        } catch {
            // Stats are non-critical
        }
    }
}
