//
//  SignInView.swift
//  BusTicketBooking
//
//  Created by macos on 1/3/26.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Logo Header
                    VStack(spacing: 12) {
                        Image(systemName: "bus.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.primaryMaroon)
                        
                        Text("Bus Ticket Booking")
                            .font(.title)
                            .bold()
                            .foregroundColor(Theme.primaryMaroon)
                        
                        Text("Sign in to continue")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    // MARK: - Form Fields
                    VStack(spacing: 16) {
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
                                SecureField("Enter your password", text: $password)
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.subheadline)
                            .foregroundColor(Theme.primaryMaroon)
                        }
                    }
                    
                    // MARK: - Messages
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if let success = authViewModel.successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // MARK: - Sign In Button
                    Button {
                        Task {
                            await authViewModel.signIn(email: email, password: password)
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
                            Text("Sign In")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(email.isEmpty || password.isEmpty ? Color.gray : Theme.primaryMaroon)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    
                    // MARK: - Resend Verification
                    Button {
                        Task {
                            await authViewModel.resendVerificationEmail(email: email, password: password)
                        }
                    } label: {
                        Text("Resend Verification Email")
                            .font(.caption)
                            .foregroundColor(Theme.lightMaroon)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    
                    // MARK: - Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        NavigationLink {
                            SignUpView()
                        } label: {
                            Text("Sign Up")
                                .foregroundColor(Theme.primaryMaroon)
                                .bold()
                        }
                    }
                    .font(.subheadline)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .background(Theme.background)
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
