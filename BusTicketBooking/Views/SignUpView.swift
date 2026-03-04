//
//  SignUpView.swift
//  BusTicketBooking
//
//  Created by macos on 1/3/26.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showSuccessAlert = false
    
    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && !password.isEmpty &&
        password == confirmPassword && password.count >= 6
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.primaryMaroon)
                    
                    Text("Create Account")
                        .font(.title)
                        .bold()
                        .foregroundColor(Theme.primaryMaroon)
                    
                    Text("Sign up to get started")
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // MARK: - Form Fields
                VStack(spacing: 16) {
                    // Full Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Theme.primaryMaroon)
                            TextField("Enter your full name", text: $fullName)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                    
                    // Email
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
                    
                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Theme.primaryMaroon)
                            SecureField("Enter password (min 6 characters)", text: $password)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                    
                    // Confirm Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Theme.primaryMaroon)
                            SecureField("Confirm your password", text: $confirmPassword)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                    
                    // Validation Messages
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if !password.isEmpty && password.count < 6 {
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
                
                // MARK: - Sign Up Button
                Button {
                    Task {
                        await authViewModel.signUp(email: email, password: password, fullName: fullName)
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
                        Text("Sign Up")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Theme.primaryMaroon : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(!isFormValid || authViewModel.isLoading)
                
                // MARK: - Sign In Link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    Button("Sign In") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryMaroon)
                    .bold()
                }
                .font(.subheadline)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .background(Theme.background)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Account Created", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Please check your email to verify your account before signing in.")
        }
        .onDisappear {
            authViewModel.errorMessage = nil
            authViewModel.successMessage = nil
        }
    }
}
