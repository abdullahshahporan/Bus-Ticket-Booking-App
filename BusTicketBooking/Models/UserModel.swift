//
//  UserModel.swift
//  BusTicketBooking
//
//  Created by macos on 1/3/26.
//

import Foundation

struct NotificationPreferences {
    var emailNotifications: Bool
    var pushNotifications: Bool
    var promotionalAlerts: Bool
    var bookingUpdates: Bool
    
    init(emailNotifications: Bool = true, pushNotifications: Bool = true, promotionalAlerts: Bool = false, bookingUpdates: Bool = true) {
        self.emailNotifications = emailNotifications
        self.pushNotifications = pushNotifications
        self.promotionalAlerts = promotionalAlerts
        self.bookingUpdates = bookingUpdates
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "emailNotifications": emailNotifications,
            "pushNotifications": pushNotifications,
            "promotionalAlerts": promotionalAlerts,
            "bookingUpdates": bookingUpdates
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]?) -> NotificationPreferences {
        guard let dict = dict else { return NotificationPreferences() }
        return NotificationPreferences(
            emailNotifications: dict["emailNotifications"] as? Bool ?? true,
            pushNotifications: dict["pushNotifications"] as? Bool ?? true,
            promotionalAlerts: dict["promotionalAlerts"] as? Bool ?? false,
            bookingUpdates: dict["bookingUpdates"] as? Bool ?? true
        )
    }
}

struct UserProfile: Identifiable {
    var id: String
    var fullName: String
    var email: String
    var phone: String
    var contactNo: String
    var address: String
    var notificationPreferences: NotificationPreferences
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, fullName: String, email: String, phone: String = "", contactNo: String = "", address: String = "", notificationPreferences: NotificationPreferences = NotificationPreferences(), createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.contactNo = contactNo
        self.address = address
        self.notificationPreferences = notificationPreferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
