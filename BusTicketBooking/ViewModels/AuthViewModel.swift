//
//  AuthViewModel.swift
//  BusTicketBooking
//
//  Created by macos on 1/3/26.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // MARK: - Token Management: Auth state listener
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let user = user, user.isEmailVerified {
                    self.userSession = user
                    if self.currentUser == nil {
                        await self.fetchUserProfile()
                    }
                } else {
                    self.userSession = nil
                    self.currentUser = nil
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Refresh Token
    func refreshToken() async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)
            _ = tokenResult.token
            self.userSession = user
        } catch {
            self.errorMessage = "Session expired. Please sign in again."
            signOut()
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            try await result.user.sendEmailVerification()
            
            let userProfile = UserProfile(
                id: result.user.uid,
                fullName: fullName,
                email: email
            )
            
            try await saveUserProfile(userProfile)
            
            // Sign out so user must verify email before signing in
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            
            isLoading = false
            successMessage = "Account created successfully! Please check your email to verify your account before signing in."
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Resend Verification Email
    func resendVerificationEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Temporarily remove listener to avoid state flickering
            if let handle = authStateHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            if !result.user.isEmailVerified {
                try await result.user.sendEmailVerification()
                try Auth.auth().signOut()
                isLoading = false
                successMessage = "Verification email resent. Please check your inbox."
            } else {
                try Auth.auth().signOut()
                isLoading = false
                successMessage = "Your email is already verified. Please sign in."
            }
            
            // Re-attach listener
            setupAuthListener()
        } catch {
            // Re-attach listener on error too
            setupAuthListener()
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Check if email is verified
            if !result.user.isEmailVerified {
                try Auth.auth().signOut()
                isLoading = false
                errorMessage = "Please verify your email before signing in. Check your inbox for the verification link."
                return
            }
            
            self.userSession = result.user
            isLoading = false
            await fetchUserProfile()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            self.errorMessage = nil
            self.successMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
            successMessage = "Password reset email sent. Please check your inbox."
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Change Password
    func changePassword(currentPassword: String, newPassword: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard let user = Auth.auth().currentUser, let email = user.email else {
            isLoading = false
            errorMessage = "No user is currently logged in."
            return
        }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
            isLoading = false
            successMessage = "Password changed successfully."
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Fetch User Profile from Firestore
    func fetchUserProfile() async {
        guard let uid = userSession?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            
            if let data = snapshot.data() {
                let notifPrefs = NotificationPreferences.fromDictionary(data["notificationPreferences"] as? [String: Any])
                
                self.currentUser = UserProfile(
                    id: uid,
                    fullName: data["fullName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    phone: data["phone"] as? String ?? "",
                    contactNo: data["contactNo"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    notificationPreferences: notifPrefs,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            } else {
                // Document doesn't exist in Firestore (edge case: Auth succeeded but Firestore save failed during signup)
                // Create a basic profile so the user isn't stuck
                let email = userSession?.email ?? ""
                let profile = UserProfile(id: uid, fullName: email.components(separatedBy: "@").first ?? "User", email: email)
                try await saveUserProfile(profile)
                self.currentUser = profile
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Save User Profile to Firestore
    private func saveUserProfile(_ profile: UserProfile) async throws {
        let data: [String: Any] = [
            "fullName": profile.fullName,
            "email": profile.email,
            "phone": profile.phone,
            "contactNo": profile.contactNo,
            "address": profile.address,
            "notificationPreferences": profile.notificationPreferences.toDictionary(),
            "createdAt": Timestamp(date: profile.createdAt),
            "updatedAt": Timestamp(date: profile.updatedAt)
        ]
        
        try await db.collection("users").document(profile.id).setData(data)
    }
    
    // MARK: - Update Profile
    func updateProfile(fullName: String, phone: String, contactNo: String, address: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard let uid = userSession?.uid else {
            isLoading = false
            errorMessage = "No user is currently logged in."
            return
        }
        
        var data: [String: Any] = [
            "fullName": fullName,
            "phone": phone,
            "contactNo": contactNo,
            "address": address,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Include email if we have it (for create-or-update safety)
        if let email = userSession?.email {
            data["email"] = email
        }
        
        do {
            try await db.collection("users").document(uid).setData(data, merge: true)
            self.currentUser?.fullName = fullName
            self.currentUser?.phone = phone
            self.currentUser?.contactNo = contactNo
            self.currentUser?.address = address
            isLoading = false
            successMessage = "Profile updated successfully."
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Update Notification Preferences
    func updateNotificationPreferences(_ prefs: NotificationPreferences) async {
        errorMessage = nil
        successMessage = nil
        
        guard let uid = userSession?.uid else {
            errorMessage = "No user is currently logged in."
            return
        }
        
        let data: [String: Any] = [
            "notificationPreferences": prefs.toDictionary(),
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(uid).setData(data, merge: true)
            self.currentUser?.notificationPreferences = prefs
            successMessage = "Notification preferences updated."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
