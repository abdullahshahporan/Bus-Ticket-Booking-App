//
//  ChangePasswordView.swift
//  BusTicketBooking
//
//  Created by macos on 1/3/26.
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var showSuccessAlert = false
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty &&
        newPassword == confirmNewPassword && newPassword.count >= 6
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.primaryMaroon)
                    
                    Text("Change Password")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Theme.primaryMaroon)
                }
                .padding(.top, 20)
                
                // MARK: - Form Fields
                VStack(spacing: 16) {
                    // Current Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Theme.primaryMaroon)
                            SecureField("Enter current password", text: $currentPassword)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                    
                    // New Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .foregroundColor(Theme.primaryMaroon)
                            SecureField("Enter new password (min 6 characters)", text: $newPassword)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                    
                    // Confirm New Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm New Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .foregroundColor(Theme.primaryMaroon)
                            SecureField("Confirm new password", text: $confirmNewPassword)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                    
                    // Validation Messages
                    if !confirmNewPassword.isEmpty && newPassword != confirmNewPassword {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if !newPassword.isEmpty && newPassword.count < 6 {
                        Text("Password must be at least 6 characters")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // MARK: - Error Message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // MARK: - Change Password Button
                Button {
                    Task {
                        await authViewModel.changePassword(
                            currentPassword: currentPassword,
                            newPassword: newPassword
                        )
                        if authViewModel.errorMessage == nil && authViewModel.successMessage != nil {
                            showSuccessAlert = true
                        }
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryMaroon)
                            .cornerRadius(12)
                    } else {
                        Text("Change Password")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Theme.primaryMaroon : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(!isFormValid || authViewModel.isLoading)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .background(Theme.background)
        .navigationTitle("Change Password")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been changed successfully.")
        }
        .onDisappear {
            authViewModel.errorMessage = nil
            authViewModel.successMessage = nil
        }
    }
}
