//
//  BusTicketBookingApp.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI
import FirebaseCore

@main
struct BusTicketBookingApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
