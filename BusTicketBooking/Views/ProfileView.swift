//
//  ProfileView.swift
//  BusTicketBooking
//
//  Created by macos on 1/3/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isEditing = false
    @State private var fullName = ""
    @State private var phone = ""
    @State private var contactNo = ""
    @State private var address = ""
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Profile Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Theme.primaryMaroon, Theme.lightMaroon]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Text(initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(authViewModel.currentUser?.fullName ?? "User")
                            .font(.title2)
                            .bold()
                        
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // MARK: - Profile Info
                    VStack(spacing: 16) {
                        // Full Name
                        profileField(icon: "person.fill", label: "Full Name") {
                            if isEditing {
                                TextField("Full Name", text: $fullName)
                                    .autocorrectionDisabled()
                            } else {
                                Text(authViewModel.currentUser?.fullName ?? "Not set")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        
                        // Email (non-editable)
                        profileField(icon: "envelope.fill", label: "Email") {
                            Text(authViewModel.currentUser?.email ?? "Not set")
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        
                        // Phone
                        profileField(icon: "phone.fill", label: "Phone") {
                            if isEditing {
                                TextField("Phone number", text: $phone)
                                    #if os(iOS)
                                    .keyboardType(.phonePad)
                                    #endif
                            } else {
                                Text(displayText(for: authViewModel.currentUser?.phone))
                                    .foregroundColor(hasValue(authViewModel.currentUser?.phone) ? .primary : .secondary)
                                Spacer()
                            }
                        }
                        
                        // Contact No.
                        profileField(icon: "phone.circle.fill", label: "Contact No.") {
                            if isEditing {
                                TextField("Contact number", text: $contactNo)
                                    #if os(iOS)
                                    .keyboardType(.phonePad)
                                    #endif
                            } else {
                                Text(displayText(for: authViewModel.currentUser?.contactNo))
                                    .foregroundColor(hasValue(authViewModel.currentUser?.contactNo) ? .primary : .secondary)
                                Spacer()
                            }
                        }
                        
                        // Address
                        profileField(icon: "location.fill", label: "Address") {
                            if isEditing {
                                TextField("Address", text: $address)
                                    .autocorrectionDisabled()
                            } else {
                                Text(displayText(for: authViewModel.currentUser?.address))
                                    .foregroundColor(hasValue(authViewModel.currentUser?.address) ? .primary : .secondary)
                                Spacer()
                            }
                        }
                    }
                    
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
                    
                    // MARK: - Edit / Save Button
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
                            loadProfileData()
                            isEditing = true
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
                            HStack {
                                Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                                Text(isEditing ? "Save Profile" : "Edit Profile")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryMaroon)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .disabled(authViewModel.isLoading)
                    
                    // Cancel Edit Button
                    if isEditing {
                        Button {
                            isEditing = false
                        } label: {
                            Text("Cancel")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.cardBackground)
                                .foregroundColor(Theme.primaryMaroon)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.primaryMaroon, lineWidth: 1)
                                )
                        }
                    }
                    
                    // MARK: - Settings Section
                    VStack(spacing: 0) {
                        // Dark Mode
                        HStack(spacing: 14) {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(Theme.primaryMaroon)
                                .font(.title3)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dark Mode")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Switch app appearance")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isDarkMode)
                                .tint(Theme.primaryMaroon)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider().padding(.horizontal)
                        
                        // Notification Preferences
                        NavigationLink {
                            NotificationPreferencesView()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(Theme.primaryMaroon)
                                    .font(.title3)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notification Preferences")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("Manage your notifications")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        
                        Divider().padding(.horizontal)
                        
                        // Change Password
                        NavigationLink {
                            ChangePasswordView()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "key.fill")
                                    .foregroundColor(Theme.primaryMaroon)
                                    .font(.title3)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Change Password")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("Update your password")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                    .background(Theme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: .gray.opacity(0.1), radius: 5)
                    
                    // MARK: - Sign Out
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
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .background(Theme.adaptiveBackground)
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onAppear {
                authViewModel.errorMessage = nil
                authViewModel.successMessage = nil
                Task {
                    await authViewModel.fetchUserProfile()
                }
            }
        }
    }
    
    // MARK: - Reusable Profile Field
    @ViewBuilder
    private func profileField<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.primaryMaroon)
                content()
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
    
    // MARK: - Helper Properties
    private var initials: String {
        let name = authViewModel.currentUser?.fullName ?? ""
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return initials.isEmpty ? "U" : initials.joined()
    }
    
    private func loadProfileData() {
        fullName = authViewModel.currentUser?.fullName ?? ""
        phone = authViewModel.currentUser?.phone ?? ""
        contactNo = authViewModel.currentUser?.contactNo ?? ""
        address = authViewModel.currentUser?.address ?? ""
    }
    
    private func displayText(for value: String?) -> String {
        guard let value = value, !value.isEmpty else {
            return "Not set"
        }
        return value
    }
    
    private func hasValue(_ value: String?) -> Bool {
        guard let value = value else { return false }
        return !value.isEmpty
    }
}
