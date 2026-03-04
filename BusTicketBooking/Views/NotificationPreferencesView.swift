//
//  NotificationPreferencesView.swift
//  BusTicketBooking
//
//  Created by macos on 1/3/26.
//

import SwiftUI

struct NotificationPreferencesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var emailNotifications: Bool = true
    @State private var pushNotifications: Bool = true
    @State private var promotionalAlerts: Bool = false
    @State private var bookingUpdates: Bool = true
    @State private var showSavedAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.primaryMaroon)
                    
                    Text("Notification Preferences")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Theme.primaryMaroon)
                    
                    Text("Choose what notifications you want to receive")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                }
                .padding(.top, 20)
                
                // MARK: - Notification Toggles
                VStack(spacing: 0) {
                    // Email Notifications
                    notificationToggle(
                        icon: "envelope.fill",
                        title: "Email Notifications",
                        subtitle: "Receive booking confirmations via email",
                        isOn: $emailNotifications
                    )
                    
                    Divider().padding(.horizontal)
                    
                    // Push Notifications
                    notificationToggle(
                        icon: "iphone.badge.play",
                        title: "Push Notifications",
                        subtitle: "Get notified about trip updates",
                        isOn: $pushNotifications
                    )
                    
                    Divider().padding(.horizontal)
                    
                    // Booking Updates
                    notificationToggle(
                        icon: "ticket.fill",
                        title: "Booking Updates",
                        subtitle: "Updates about your booked trips",
                        isOn: $bookingUpdates
                    )
                    
                    Divider().padding(.horizontal)
                    
                    // Promotional Alerts
                    notificationToggle(
                        icon: "megaphone.fill",
                        title: "Promotional Alerts",
                        subtitle: "Deals, discounts and special offers",
                        isOn: $promotionalAlerts
                    )
                }
                .background(Theme.cardBackground)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                
                // MARK: - Messages
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                if let success = authViewModel.successMessage {
                    Text(success)
                        .foregroundColor(.green)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // MARK: - Save Button
                Button {
                    let prefs = NotificationPreferences(
                        emailNotifications: emailNotifications,
                        pushNotifications: pushNotifications,
                        promotionalAlerts: promotionalAlerts,
                        bookingUpdates: bookingUpdates
                    )
                    Task {
                        await authViewModel.updateNotificationPreferences(prefs)
                        if authViewModel.errorMessage == nil {
                            showSavedAlert = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Preferences")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primaryMaroon)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .background(Theme.background)
        .navigationTitle("Notifications")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            loadPreferences()
            authViewModel.errorMessage = nil
            authViewModel.successMessage = nil
        }
        .alert("Saved", isPresented: $showSavedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your notification preferences have been saved.")
        }
    }
    
    private func loadPreferences() {
        guard let prefs = authViewModel.currentUser?.notificationPreferences else { return }
        emailNotifications = prefs.emailNotifications
        pushNotifications = prefs.pushNotifications
        promotionalAlerts = prefs.promotionalAlerts
        bookingUpdates = prefs.bookingUpdates
    }
    
    @ViewBuilder
    private func notificationToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(Theme.primaryMaroon)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(Theme.primaryMaroon)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
