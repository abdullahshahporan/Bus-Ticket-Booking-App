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
    @Published var isAdmin = false
    @Published var isOperator = false
    @Published var hasResolvedSession = false
    
    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let user = user {
                    let resolvedRole = await self.fetchStoredRole(
                        userId: user.uid,
                        email: user.email
                    )

                    if user.isEmailVerified || !resolvedRole.requiresEmailVerification {
                        self.userSession = user
                        self.applyRole(resolvedRole)
                        await self.fetchUserProfile(expectedRole: resolvedRole)
                    } else {
                        self.clearSessionState()
                    }
                } else {
                    self.clearSessionState()
                }

                self.hasResolvedSession = true
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
            self.hasResolvedSession = true
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
        hasResolvedSession = false
        
        do {
            let normalizedEmail = DefaultAdminAccount.normalizedEmail(email)
            let sanitizedPassword = DefaultAdminAccount.sanitizedPassword(password)
            let result = try await Auth.auth().createUser(withEmail: normalizedEmail, password: sanitizedPassword)
            let role = defaultRole(for: normalizedEmail)

            if role.requiresEmailVerification {
                try await result.user.sendEmailVerification()
            }
            
            let userProfile = UserProfile(
                id: result.user.uid,
                fullName: fullName,
                email: normalizedEmail,
                role: role.rawValue
            )
            
            try await saveUserProfile(userProfile)
            
            if role.requiresEmailVerification {
                try Auth.auth().signOut()
                clearSessionState()
                successMessage = "Account created successfully! Please check your email to verify your account before signing in."
            } else {
                self.userSession = result.user
                self.applyRole(role)
                await self.fetchUserProfile(expectedRole: role)
                successMessage = "\(role.displayName) account created successfully."
            }
            
            isLoading = false
            hasResolvedSession = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            hasResolvedSession = true
        }
    }
    
    // MARK: - Resend Verification Email
    func resendVerificationEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let normalizedEmail = DefaultAdminAccount.normalizedEmail(email)
            let sanitizedPassword = DefaultAdminAccount.sanitizedPassword(password)

            if let handle = authStateHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
            
            let result = try await Auth.auth().signIn(withEmail: normalizedEmail, password: sanitizedPassword)
            let role = await fetchStoredRole(userId: result.user.uid, email: result.user.email)

            if !role.requiresEmailVerification {
                try Auth.auth().signOut()
                isLoading = false
                successMessage = "This account can sign in without email verification."
            } else if !result.user.isEmailVerified {
                try await result.user.sendEmailVerification()
                try Auth.auth().signOut()
                isLoading = false
                successMessage = "Verification email resent. Please check your inbox."
            } else {
                try Auth.auth().signOut()
                isLoading = false
                successMessage = "Your email is already verified. Please sign in."
            }
            
            setupAuthListener()
            hasResolvedSession = true
        } catch {
            setupAuthListener()
            isLoading = false
            errorMessage = error.localizedDescription
            hasResolvedSession = true
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        hasResolvedSession = false

        let normalizedEmail = DefaultAdminAccount.normalizedEmail(email)
        let sanitizedPassword = DefaultAdminAccount.sanitizedPassword(password)
        
        do {
            let result = try await Auth.auth().signIn(withEmail: normalizedEmail, password: sanitizedPassword)
            let resolvedRole = await fetchStoredRole(
                userId: result.user.uid,
                email: result.user.email ?? normalizedEmail
            )
            
            if resolvedRole.requiresEmailVerification && !result.user.isEmailVerified {
                try Auth.auth().signOut()
                isLoading = false
                errorMessage = "Please verify your email before signing in. Check your inbox for the verification link."
                hasResolvedSession = true
                return
            }
            
            self.userSession = result.user
            self.applyRole(resolvedRole)
            isLoading = false
            await fetchUserProfile(expectedRole: resolvedRole)
            hasResolvedSession = true
        } catch {
            if shouldProvisionDefaultAdmin(email: normalizedEmail, password: sanitizedPassword, error: error) {
                do {
                    let result = try await provisionDefaultAdmin(email: normalizedEmail, password: sanitizedPassword)
                    self.userSession = result.user
                    self.applyRole(.admin)
                    isLoading = false
                    successMessage = "Default admin account created successfully."
                    await fetchUserProfile(expectedRole: .admin)
                    hasResolvedSession = true
                    return
                } catch {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    hasResolvedSession = true
                    return
                }
            }

            isLoading = false
            errorMessage = error.localizedDescription
            hasResolvedSession = true
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            clearSessionState()
            self.errorMessage = nil
            self.successMessage = nil
            self.hasResolvedSession = true
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
            let normalizedEmail = DefaultAdminAccount.normalizedEmail(email)
            try await Auth.auth().sendPasswordReset(withEmail: normalizedEmail)
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
    func fetchUserProfile(expectedRole: AppUserRole? = nil) async {
        guard let uid = userSession?.uid else { return }
        let fallbackRole = expectedRole ?? defaultRole(for: userSession?.email)
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            
            if let data = snapshot.data() {
                let resolvedRole = AppUserRole(rawValue: data["role"] as? String ?? fallbackRole.rawValue) ?? fallbackRole
                let notifPrefs = NotificationPreferences.fromDictionary(data["notificationPreferences"] as? [String: Any])
                
                self.currentUser = UserProfile(
                    id: uid,
                    fullName: data["fullName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    phone: data["phone"] as? String ?? "",
                    contactNo: data["contactNo"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    role: resolvedRole.rawValue,
                    notificationPreferences: notifPrefs,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                )
                self.applyRole(resolvedRole)
            } else {
                let email = userSession?.email ?? ""
                let profile = UserProfile(
                    id: uid,
                    fullName: email.components(separatedBy: "@").first ?? fallbackRole.displayName,
                    email: email,
                    role: fallbackRole.rawValue
                )
                try await saveUserProfile(profile)
                self.currentUser = profile
                self.applyRole(fallbackRole)
            }
        } catch {
            let nsError = error as NSError
            let permissionCode = FirestoreErrorCode.permissionDenied.rawValue

            if nsError.domain == FirestoreErrorDomain, nsError.code == permissionCode {
                let email = userSession?.email ?? ""
                let fallbackName = userSession?.displayName
                    ?? email.components(separatedBy: "@").first
                    ?? fallbackRole.displayName

                self.currentUser = UserProfile(
                    id: uid,
                    fullName: fallbackName,
                    email: email,
                    role: fallbackRole.rawValue
                )
                self.applyRole(fallbackRole)
                self.errorMessage = "Unable to load full profile from Firestore: Missing or insufficient permissions."
                return
            }

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
            "role": profile.role,
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

    private func fetchStoredRole(userId: String, email: String?) async -> AppUserRole {
        do {
            let snapshot = try await db.collection("users").document(userId).getDocument()
            if let roleString = snapshot.data()?["role"] as? String,
               let role = AppUserRole(rawValue: roleString) {
                return role
            }
        } catch {
            // Keep the role fallback lightweight so auth recovery still works.
        }

        return defaultRole(for: email)
    }

    private func defaultRole(for email: String?) -> AppUserRole {
        let normalizedEmail = DefaultAdminAccount.normalizedEmail(email)
        if normalizedEmail == DefaultAdminAccount.email {
            return .admin
        }
        return .user
    }

    private func shouldProvisionDefaultAdmin(email: String, password: String, error: Error) -> Bool {
        guard DefaultAdminAccount.matches(email: email, password: password) else {
            return false
        }

        let authCode = AuthErrorCode(rawValue: (error as NSError).code)
        return authCode == .userNotFound || authCode == .invalidCredential
    }

    private func provisionDefaultAdmin(email: String, password: String) async throws -> AuthDataResult {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let profile = UserProfile(
                id: result.user.uid,
                fullName: DefaultAdminAccount.fullName,
                email: email,
                role: AppUserRole.admin.rawValue
            )
            try await saveUserProfile(profile)
            return result
        } catch {
            let authCode = AuthErrorCode(rawValue: (error as NSError).code)
            if authCode == .emailAlreadyInUse {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                let profile = UserProfile(
                    id: result.user.uid,
                    fullName: DefaultAdminAccount.fullName,
                    email: email,
                    role: AppUserRole.admin.rawValue
                )
                try await saveUserProfile(profile)
                return result
            }
            throw error
        }
    }

    private func applyRole(_ role: AppUserRole) {
        isAdmin = role == .admin
        isOperator = role == .operator
    }

    private func clearSessionState() {
        userSession = nil
        currentUser = nil
        isAdmin = false
        isOperator = false
    }
}
