import SwiftUI

struct AdminProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var fullName = ""
    @State private var phone = ""
    @State private var contactNo = ""
    @State private var address = ""
    @State private var isEditing = false
    @State private var showSignOutAlert = false
    @State private var showMaintenanceAlert = false

    @StateObject private var adminVM = AdminViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 56))
                            .foregroundColor(Theme.primaryColor)
                        Text(authViewModel.currentUser?.fullName ?? "Admin")
                            .font(.title3)
                            .bold()
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    adminField(label: "Full Name", icon: "person.fill") {
                        if isEditing {
                            TextField("Full Name", text: $fullName)
                                .autocorrectionDisabled()
                        } else {
                            Text(authViewModel.currentUser?.fullName ?? "Not set")
                            Spacer()
                        }
                    }

                    adminField(label: "Email", icon: "envelope.fill") {
                        Text(authViewModel.currentUser?.email ?? "Not set")
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    adminField(label: "Phone", icon: "phone.fill") {
                        if isEditing {
                            TextField("Phone", text: $phone)
                                #if os(iOS)
                                .keyboardType(.phonePad)
                                #endif
                        } else {
                            Text(displayText(authViewModel.currentUser?.phone))
                                .foregroundColor(displayText(authViewModel.currentUser?.phone) == "Not set" ? .secondary : .primary)
                            Spacer()
                        }
                    }

                    adminField(label: "Contact No.", icon: "phone.circle.fill") {
                        if isEditing {
                            TextField("Contact No.", text: $contactNo)
                                #if os(iOS)
                                .keyboardType(.phonePad)
                                #endif
                        } else {
                            Text(displayText(authViewModel.currentUser?.contactNo))
                                .foregroundColor(displayText(authViewModel.currentUser?.contactNo) == "Not set" ? .secondary : .primary)
                            Spacer()
                        }
                    }

                    adminField(label: "Address", icon: "location.fill") {
                        if isEditing {
                            TextField("Address", text: $address)
                                .autocorrectionDisabled()
                        } else {
                            Text(displayText(authViewModel.currentUser?.address))
                                .foregroundColor(displayText(authViewModel.currentUser?.address) == "Not set" ? .secondary : .primary)
                            Spacer()
                        }
                    }

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

                    if let error = adminVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    if let success = adminVM.successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        if isEditing {
                            Task {
                                await authViewModel.updateProfile(
                                    fullName: fullName,
                                    phone: phone,
                                    contactNo: contactNo,
                                    address: address
                                )
                                if authViewModel.errorMessage == nil {
                                    isEditing = false
                                }
                            }
                        } else {
                            fullName = authViewModel.currentUser?.fullName ?? ""
                            phone = authViewModel.currentUser?.phone ?? ""
                            contactNo = authViewModel.currentUser?.contactNo ?? ""
                            address = authViewModel.currentUser?.address ?? ""
                            isEditing = true
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primaryColor)
                                .cornerRadius(12)
                        } else {
                            Text(isEditing ? "Save Profile" : "Edit Profile")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(authViewModel.isLoading)

                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.cardBackground)
                        .foregroundColor(Theme.primaryColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.primaryColor, lineWidth: 1)
                        )
                    }

                    Button {
                        showMaintenanceAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                            Text("Run Firestore Cleanup")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.cardBackground)
                        .foregroundColor(Theme.primaryColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.primaryColor.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(adminVM.isLoading)

                    Button {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(Theme.background)
            .navigationTitle("Admin Profile")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Run Firestore Cleanup", isPresented: $showMaintenanceAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Run", role: .destructive) {
                    Task {
                        await adminVM.cleanupAndReseedIfNeeded()
                    }
                }
            } message: {
                Text("This will normalize bus and booking data, and seed sample buses only if busTrips is empty.")
            }
            .onAppear {
                Task { await authViewModel.fetchUserProfile() }
            }
        }
    }

    private func displayText(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "Not set" }
        return value
    }

    @ViewBuilder
    private func adminField<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.primaryColor)
                content()
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
}
