//
//  CreateOperatorSheet.swift
//  BusTicketBooking
//

import SwiftUI

@MainActor
struct CreateOperatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var adminVM: AdminViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var isFormValid: Bool {
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 46))
                            .foregroundColor(Theme.primaryColor)
                        Text("Create Bus Operator")
                            .font(.title2)
                            .bold()
                        Text("Add the operator's email and password. The email will be stored, and verification is skipped for now.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    operatorField(
                        title: "Email",
                        icon: "envelope.fill",
                        placeholder: "operator@example.com",
                        text: $email,
                        isSecure: false
                    )

                    operatorField(
                        title: "Password",
                        icon: "lock.fill",
                        placeholder: "Minimum 6 characters",
                        text: $password,
                        isSecure: true
                    )

                    operatorField(
                        title: "Confirm Password",
                        icon: "lock.rotation",
                        placeholder: "Re-enter password",
                        text: $confirmPassword,
                        isSecure: true
                    )

                    if !confirmPassword.isEmpty && confirmPassword != password {
                        Text("Passwords do not match.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if let error = adminVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    if let success = adminVM.successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            let success = await adminVM.createOperatorAccount(
                                email: email,
                                password: password
                            )
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        if adminVM.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primaryColor)
                                .cornerRadius(14)
                        } else {
                            Text("Create Operator")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? Theme.primaryColor : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .disabled(!isFormValid || adminVM.isLoading)
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("New Operator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func operatorField(
        title: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.primaryColor)
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                        .autocorrectionDisabled()
                }
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
