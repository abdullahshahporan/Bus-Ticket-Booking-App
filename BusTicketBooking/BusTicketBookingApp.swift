//
//  BusTicketBookingApp.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI
import FirebaseCore

@main
@MainActor
struct BusTicketBookingApp: App {
    
    init() {
        FirebaseApp.configure()
        BookingNotificationService.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
