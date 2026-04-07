//
//  SeedService.swift
//  BusTicketBooking
//
//  Created by macos on 4/3/26.
//

import Foundation
import FirebaseFirestore

@MainActor
class SeedService: ObservableObject {

    static let shared = SeedService()

    @Published var status: SeedStatus = .idle

    enum SeedStatus: Equatable {
        case idle
        case running
        case done(message: String)
        case failed(message: String)
    }

    private let db = Firestore.firestore()
    private let seededKey = "firestoreSeeded_v3"

    // MARK: - Public API

    func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        Task { await runSeed() }
    }

    func forceSeed() {
        Task { await runSeed() }
    }

    // MARK: - Internal

    private func runSeed() async {
        status = .running
        do {
            try await seedCollection("popularRoutes", documents: popularRoutes)

            let busTripsWithSeats = busTrips.map { trip -> [String: Any] in
                var updatedTrip = trip
                let seatMatrix = generateSeatMatrix()
                updatedTrip["seatMatrix"] = seatMatrix
                updatedTrip["availableSeats"] = countAvailableSeats(in: seatMatrix)
                return updatedTrip
            }

            try await seedCollection("busTrips", documents: busTripsWithSeats)

            UserDefaults.standard.set(true, forKey: seededKey)

            status = .done(message: "Seeded \(popularRoutes.count) routes and \(busTrips.count) bus trips ✓")
        } catch {
            status = .failed(message: error.localizedDescription)
        }
    }

    private func seedCollection(_ name: String, documents: [[String: Any]]) async throws {
        let col = db.collection(name)
        let chunkSize = 400

        for chunk in stride(from: 0, to: documents.count, by: chunkSize) {
            let batch = db.batch()
            let end = min(chunk + chunkSize, documents.count)

            for doc in documents[chunk..<end] {
                batch.setData(doc, forDocument: col.document())
            }

            try await batch.commit()
        }
    }

    // MARK: - Seat Matrix Generator (UPDATED)

    /// Generates 40 seats (0 = available, 1 = booked)
    private func generateSeatMatrix() -> String {
        var matrix = Array(repeating: "0", count: 40)

        let frontSeatCount = Int.random(in: 3...7)
        let frontSeats = Array(0..<8)

        for index in frontSeats.shuffled().prefix(frontSeatCount) {
            matrix[index] = "1"
        }

        return matrix.joined()
    }

    private func countAvailableSeats(in matrix: String) -> Int {
        return matrix.filter { $0 == "0" }.count
    }

    // MARK: - popularRoutes

    private let popularRoutes: [[String: Any]] = [
        ["from": "Dhaka", "to": "Chattagram", "minPrice": 700],
        ["from": "Dhaka", "to": "Sylhet", "minPrice": 750],
        ["from": "Dhaka", "to": "Khulna", "minPrice": 700],
        ["from": "Dhaka", "to": "Rajshahi", "minPrice": 600],
        ["from": "Dhaka", "to": "Barisal", "minPrice": 550],
        ["from": "Dhaka", "to": "Rangpur", "minPrice": 750],
        ["from": "Dhaka", "to": "Cox's Bazar", "minPrice": 950],
        ["from": "Dhaka", "to": "Mymensingh", "minPrice": 250],
        ["from": "Dhaka", "to": "Comilla", "minPrice": 300],
        ["from": "Dhaka", "to": "Bogura", "minPrice": 500],
        ["from": "Dhaka", "to": "Faridpur", "minPrice": 300],
        ["from": "Dhaka", "to": "Jessore", "minPrice": 600],
        ["from": "Dhaka", "to": "Dinajpur", "minPrice": 850],
        ["from": "Dhaka", "to": "Tangail", "minPrice": 180],
        ["from": "Dhaka", "to": "Madaripur", "minPrice": 320],
        ["from": "Dhaka", "to": "Chandpur", "minPrice": 280],
        ["from": "Dhaka", "to": "Brahmanbaria", "minPrice": 260],
        ["from": "Dhaka", "to": "Noakhali", "minPrice": 380],
        ["from": "Dhaka", "to": "Feni", "minPrice": 350],
        ["from": "Dhaka", "to": "Pabna", "minPrice": 380],
        ["from": "Dhaka", "to": "Kushtia", "minPrice": 520],
        ["from": "Dhaka", "to": "Narayanganj", "minPrice": 80],

        ["from": "Khulna", "to": "Barisal", "minPrice": 180],
        ["from": "Khulna", "to": "Jessore", "minPrice": 150],
        ["from": "Khulna", "to": "Faridpur", "minPrice": 360],
        ["from": "Khulna", "to": "Rajshahi", "minPrice": 430],
        ["from": "Khulna", "to": "Kushtia", "minPrice": 230],

        ["from": "Khulna", "to": "Dhaka", "minPrice": 700],
        ["from": "Sylhet", "to": "Dhaka", "minPrice": 750],
        ["from": "Rajshahi", "to": "Dhaka", "minPrice": 600]
    ]

    // MARK: - busTrips (shortened example)

    private let busTrips: [[String: Any]] = [
        [
            "busName": "Green Line Paribahan",
            "source": "Dhaka",
            "destination": "Chattagram",
            "departureTime": "08:00 AM",
            "arrivalTime": "02:00 PM",
            "availableSeats": 22,
            "ticketPrice": 850,
            "busType": "AC"
        ],
        [
            "busName": "Hanif Enterprise",
            "source": "Dhaka",
            "destination": "Khulna",
            "departureTime": "07:00 AM",
            "arrivalTime": "01:00 PM",
            "availableSeats": 30,
            "ticketPrice": 800,
            "busType": "AC"
        ],
        [
            "busName": "Eagle Paribahan",
            "source": "Khulna",
            "destination": "Dhaka",
            "departureTime": "09:00 PM",
            "arrivalTime": "03:00 AM",
            "availableSeats": 20,
            "ticketPrice": 850,
            "busType": "AC"
        ]
    ]
}
