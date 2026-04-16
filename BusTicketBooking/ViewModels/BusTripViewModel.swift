//
//  BusTripViewModel.swift
//  BusTicketBooking
//
//  Created by macos on 4/3/26.
//

import Foundation
import FirebaseFirestore

@MainActor
class BusTripViewModel: ObservableObject {
    @Published var trips: [BusTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    // Fetch trips from Firestore filtered by source and destination.
    // Sorting by ticketPrice is done client-side to avoid needing
    // a composite Firestore index for the first run.
    func fetchTrips(from source: String, to destination: String) {
        let src = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let dst = destination.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !src.isEmpty, !dst.isEmpty else {
            errorMessage = "Please enter both source and destination."
            return
        }

        isLoading = true
        errorMessage = nil
        trips = []

        db.collection("busTrips")
            .whereField("source", isEqualTo: src)
            .whereField("destination", isEqualTo: dst)
            .getDocuments { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "Unable to load buses: \(error.localizedDescription)"
                        return
                    }

                    let fetched: [BusTrip] = snapshot?.documents.compactMap { doc in
                        BusTrip(documentID: doc.documentID, data: doc.data())
                    } ?? []

                    // Sort by ticket price ascending on the client side
                    self.trips = fetched.sorted { $0.ticketPrice < $1.ticketPrice }
                }
            }
    }

    func fetchOfferTrips() {
        isLoading = true
        errorMessage = nil
        trips = []

        db.collection("busTrips")
            .whereField("discount", isGreaterThan: 0)
            .getDocuments { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "Unable to load offers: \(error.localizedDescription)"
                        return
                    }

                    let fetched: [BusTrip] = snapshot?.documents.compactMap { doc in
                        BusTrip(documentID: doc.documentID, data: doc.data())
                    } ?? []

                    self.trips = fetched
                        .filter { $0.hasDiscount }
                        .sorted { lhs, rhs in
                            if lhs.discount == rhs.discount {
                                return lhs.discountedPrice < rhs.discountedPrice
                            }
                            return lhs.discount > rhs.discount
                        }
                }
            }
    }
}
