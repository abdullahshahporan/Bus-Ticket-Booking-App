//
//  RouteViewModel.swift
//  BusTicketBooking
//
//  Created by macos on 4/3/26.
//

import Foundation
import FirebaseFirestore

@MainActor
class RouteViewModel: ObservableObject {
    @Published var popularRoutes: [Route] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    // Fetches popular routes derived from actual busTrips collection.
    // Groups by source-destination and finds minimum price per route.
    func fetchPopularRoutes() {
        isLoading = true
        errorMessage = nil

        db.collection("busTrips")
            .getDocuments { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = self.firestoreErrorMessage(
                            error,
                            fallbackPrefix: "Unable to load routes"
                        )
                        return
                    }

                    let trips = snapshot?.documents.compactMap { doc in
                        BusTrip(documentID: doc.documentID, data: doc.data())
                    } ?? []

                    // Group by source-destination and find min price
                    var routeMap: [String: Int] = [:]
                    for trip in trips {
                        let key = "\(trip.source)|\(trip.destination)"
                        if let existing = routeMap[key] {
                            routeMap[key] = min(existing, trip.ticketPrice)
                        } else {
                            routeMap[key] = trip.ticketPrice
                        }
                    }

                    let routes = routeMap.compactMap { key, minPrice -> Route? in
                        let parts = key.components(separatedBy: "|")
                        guard parts.count == 2 else { return nil }
                        return Route(id: key, from: parts[0], to: parts[1], minPrice: minPrice)
                    }.sorted { $0.minPrice < $1.minPrice }

                    self.popularRoutes = Array(routes.prefix(10))
                }
            }
    }

    private func firestoreErrorMessage(_ error: Error, fallbackPrefix: String) -> String {
        let nsError = error as NSError
        let permissionCode = FirestoreErrorCode.permissionDenied.rawValue

        if nsError.domain == FirestoreErrorDomain, nsError.code == permissionCode {
            return "\(fallbackPrefix): Missing or insufficient permissions. Please update Firestore rules for busTrips read access."
        }

        return "\(fallbackPrefix): \(error.localizedDescription)"
    }
}
