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
    @Published var soldTickets: [SoldTicketRecord] = []

    private let db = Firestore.firestore()

    struct SoldTicketRecord: Identifiable {
        let id: String
        let userName: String
        let userEmail: String
        let userPhone: String
        let busName: String
        let route: String
        let travelDate: Date
        let bookingDate: Date
        let seatLabels: [String]
        let totalPrice: Int
    }

    // MARK: - Add Bus

    func addBus(
        busName: String,
        source: String,
        destination: String,
        departureTime: String,
        arrivalTime: String,
        ticketPrice: Int,
        discount: Int = 0,
        busType: String,
        pickupPoints: [String],
        droppingPoints: [String]
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let filteredPickup = pickupPoints.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let filteredDropping = droppingPoints.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let safeDiscount = min(max(discount, 0), 100)

        let data: [String: Any] = [
            "busName": busName,
            "source": source,
            "destination": destination,
            "departureTime": departureTime,
            "arrivalTime": arrivalTime,
            "ticketPrice": ticketPrice,
            "discount": safeDiscount,
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

    // MARK: - Sold Tickets

    func fetchSoldTickets() async {
        isLoading = true
        errorMessage = nil

        do {
            let bookingsSnapshot = try await db.collection("bookings")
                .whereField("status", isEqualTo: "confirmed")
                .getDocuments()

            var records: [SoldTicketRecord] = []

            for bookingDoc in bookingsSnapshot.documents {
                let data = bookingDoc.data()
                guard
                    let userId = data["userId"] as? String,
                    let busTripId = data["busTripId"] as? String
                else {
                    continue
                }

                let userSnapshot = try await db.collection("users").document(userId).getDocument()
                let tripSnapshot = try await db.collection("busTrips").document(busTripId).getDocument()

                let userData = userSnapshot.data() ?? [:]
                let tripData = tripSnapshot.data() ?? [:]

                let userName = userData["fullName"] as? String ?? "Unknown User"
                let userEmail = userData["email"] as? String ?? ""
                let userPhone = (userData["phone"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                    ?? userData["contactNo"] as? String
                    ?? "Not provided"

                let busName = tripData["busName"] as? String ?? "Unknown Bus"
                let source = tripData["source"] as? String ?? ""
                let destination = tripData["destination"] as? String ?? ""

                let bookingTimestamp = data["bookingDate"] as? TimeInterval ?? Date().timeIntervalSince1970
                let travelTimestamp = data["travelDate"] as? TimeInterval ?? bookingTimestamp
                let seatLabels = data["seatLabels"] as? [String] ?? []
                let totalPrice = data["totalPrice"] as? Int ?? 0

                records.append(
                    SoldTicketRecord(
                        id: bookingDoc.documentID,
                        userName: userName,
                        userEmail: userEmail,
                        userPhone: userPhone,
                        busName: busName,
                        route: "\(source) → \(destination)",
                        travelDate: Date(timeIntervalSince1970: travelTimestamp),
                        bookingDate: Date(timeIntervalSince1970: bookingTimestamp),
                        seatLabels: seatLabels,
                        totalPrice: totalPrice
                    )
                )
            }

            soldTickets = records.sorted { $0.bookingDate > $1.bookingDate }
            isLoading = false
        } catch {
            errorMessage = "Failed to load sold tickets: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
