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
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                Group {
                    if authViewModel.userSession != nil {
                        if authViewModel.isAdmin {
                            AdminDashboardView()
                        } else {
                            MainTabView()
                        }
                    } else {
                        SignInView()
                    }
                }
                .transition(.opacity)
            }
        }
        .environmentObject(authViewModel)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}
