//
//  ForgotPasswordView.swift
//  BusTicketBooking
//
//  Created by macos on 1/3/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.primaryMaroon)
                        
                        Text("Reset Password")
                            .font(.title)
                            .bold()
                            .foregroundColor(Theme.primaryMaroon)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // MARK: - Email Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Theme.primaryMaroon)
                            TextField("Enter your email", text: $email)
                                #if os(iOS)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                #endif
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                    
                    // MARK: - Error Message
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // MARK: - Reset Button
                    Button {
                        Task {
                            await authViewModel.resetPassword(email: email)
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
                            Text("Send Reset Link")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(email.isEmpty ? Color.gray : Theme.primaryMaroon)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(email.isEmpty || authViewModel.isLoading)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .background(Theme.background)
            .navigationTitle("Reset Password")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Email Sent", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Password reset email has been sent. Please check your inbox.")
            }
            .onDisappear {
                authViewModel.errorMessage = nil
                authViewModel.successMessage = nil
            }
        }
    }
}
