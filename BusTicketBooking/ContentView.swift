//
//  ContentView.swift
//  BusTicketBooking
//  Roll: 2107042, 2107049, 2107056
//  Created by macos on 26/2/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .environmentObject(authViewModel)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
