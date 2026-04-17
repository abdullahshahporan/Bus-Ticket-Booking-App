//
//  BookingNotificationService.swift
//  BusTicketBooking
//

import Foundation
import UserNotifications

enum BookingNotificationResult {
    case sent
    case disabledByPreferences
    case denied
    case failed
}

final class BookingNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = BookingNotificationService()

    private override init() {
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    func scheduleBookingConfirmation(
        for confirmation: BookingConfirmation,
        preferences: NotificationPreferences?
    ) async -> BookingNotificationResult {
        guard shouldSendNotification(for: preferences) else {
            return .disabledByPreferences
        }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            guard granted else { return .denied }
        } else if settings.authorizationStatus != .authorized && settings.authorizationStatus != .provisional {
            return .denied
        }

        let content = UNMutableNotificationContent()
        content.title = "Booking Confirmed"
        content.body = notificationBody(for: confirmation)
        content.sound = .default
        content.badge = NSNumber(value: 1)

        let request = UNNotificationRequest(
            identifier: "booking-confirmation-\(confirmation.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        do {
            try await center.add(request)
            return .sent
        } catch {
            return .failed
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    private func shouldSendNotification(for preferences: NotificationPreferences?) -> Bool {
        guard let preferences else { return true }
        return preferences.pushNotifications && preferences.bookingUpdates
    }

    private func notificationBody(for confirmation: BookingConfirmation) -> String {
        let seats = confirmation.seatLabels.joined(separator: ", ")
        return "\(confirmation.trip.busName) | \(confirmation.trip.source) -> \(confirmation.trip.destination) | Seats: \(seats)"
    }
}
