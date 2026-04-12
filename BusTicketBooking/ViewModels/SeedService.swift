//
//  SeedService.swift
//  BusTicketBooking
//
//  Created by macos on 4/3/26.
//

import Foundation

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

    // MARK: - Public API
    // All data is now managed through the Admin Panel.

    func seedIfNeeded() {
        // No-op: Bus data is managed via Admin Panel
    }

    func forceSeed() {
        // No-op: Bus data is managed via Admin Panel
    }
}
