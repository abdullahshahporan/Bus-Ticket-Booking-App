//
//  BookingConfirmationView.swift
//  BusTicketBooking
//

import SwiftUI
import FirebaseAuth

@MainActor
struct BookingConfirmationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    let confirmation: BookingConfirmation

    @State private var isPaying = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var showPaymentAlert = false
    @State private var paymentMessage = ""
    @State private var hasConfirmed = false
    @State private var savedBooking: BookingConfirmation?

    @StateObject private var bookingViewModel = BookingViewModel()

    private var bookingDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private var departureDateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private var passengerName: String {
        if let profileName = authViewModel.currentUser?.fullName, !profileName.isEmpty {
            return profileName
        }
        if let displayName = authViewModel.userSession?.displayName, !displayName.isEmpty {
            return displayName
        }
        if let email = authViewModel.userSession?.email, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? "Passenger"
        }
        return "Passenger"
    }

    private var passengerPhone: String {
        let profilePhone = authViewModel.currentUser?.phone ?? ""
        if !profilePhone.isEmpty { return profilePhone }
        let contactNo = authViewModel.currentUser?.contactNo ?? ""
        if !contactNo.isEmpty { return contactNo }
        return "Not provided"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                detailsSection
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                payButton
                if pdfURL != nil {
                    downloadButton
                }
            }
            .padding()
            .background(Theme.background)
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL = pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }
        .alert("Booking Confirmed", isPresented: $showPaymentAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(paymentMessage)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Ticket Preview")
                .font(.title2)
                .bold()
            Text("Booking ID: \(confirmation.id)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(spacing: 12) {
            detailRow(label: "Route",     value: "\(confirmation.trip.source) -> \(confirmation.trip.destination)")
            detailRow(label: "Bus",       value: confirmation.trip.busName)
            if confirmation.trip.hasDiscount {
                detailRow(
                    label: "Fare",
                    value: "\(confirmation.trip.discount)% OFF (\(confirmation.trip.priceFormatted) -> \(confirmation.trip.discountedPriceFormatted))"
                )
            }
            detailRow(label: "Passenger", value: passengerName)
            detailRow(label: "Phone",     value: passengerPhone)
            detailRow(label: "Departure", value: departureDisplay)
            detailRow(label: "Seats",     value: confirmation.seatLabels.joined(separator: ", "))
            detailRow(label: "Booked",    value: bookingDateFormatter.string(from: confirmation.bookingDate))
            detailRow(label: "Total",     value: "BDT \(confirmation.totalPrice)")
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(14)
    }

    private var departureDisplay: String {
        if let dt = departureDateTime {
            return departureDateTimeFormatter.string(from: dt)
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return "\(confirmation.trip.departureTime), \(df.string(from: confirmation.travelDate))"
    }

    private var departureDateTime: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"
        guard let timeDate = formatter.date(from: confirmation.trip.departureTime) else { return nil }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: confirmation.travelDate)
        dateComponents.hour   = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = 0
        return calendar.date(from: dateComponents)
    }

    // MARK: - Buttons

    private var payButton: some View {
        Button(action: handlePay) {
            if isPaying {
                ProgressView().tint(.white)
            } else {
                Text(hasConfirmed ? "Confirmed" : "Confirm Booking")
                    .bold()
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(hasConfirmed ? Color.gray : Theme.primaryColor)
        .foregroundColor(.white)
        .cornerRadius(14)
        .disabled(isPaying || hasConfirmed)
    }

    private var downloadButton: some View {
        Button(action: handleDownload) {
            Label("Download Ticket", systemImage: "arrow.down.circle")
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .foregroundColor(Theme.primaryColor)
        .cornerRadius(14)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .bold()
            Spacer()
        }
    }

    // MARK: - Actions

    private func handlePay() {
        guard !isPaying, !hasConfirmed else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            paymentMessage = "User not authenticated."
            showPaymentAlert = true
            return
        }

        isPaying = true

        Task {
            // ✅ Call the existing bookSeats method on BookingViewModel
            let saved = await bookingViewModel.bookSeats(
                confirmation.seatIndices,
                for: confirmation.trip,
                userId: userId,
                totalPrice: confirmation.totalPrice,
                travelDate: confirmation.travelDate
            )

            guard let saved = saved else {
                paymentMessage = bookingViewModel.errorMessage
                    ?? "Failed to confirm booking."
                showPaymentAlert = true
                isPaying = false
                return
            }

            savedBooking = saved

            do {
                let url = try await TicketPDFGenerator.generatePDF(
                    confirmation: saved,
                    passengerName: passengerName,
                    passengerPhone: passengerPhone
                )
                pdfURL = url
            } catch {
                // PDF generation failure is non-fatal — booking is already saved
                print("PDF generation failed: \(error.localizedDescription)")
            }

            let notificationResult = await BookingNotificationService.shared.scheduleBookingConfirmation(
                for: saved,
                preferences: authViewModel.currentUser?.notificationPreferences
            )
            paymentMessage = bookingMessage(for: notificationResult)

            hasConfirmed = true
            showPaymentAlert = true
            isPaying = false
        }
    }

    private func handleDownload() {
        guard pdfURL != nil else { return }
        showShareSheet = true
    }

    private func bookingMessage(for notificationResult: BookingNotificationResult) -> String {
        switch notificationResult {
        case .sent:
            return "Booking confirmed! A confirmation notification has been sent. Tap Download to save your ticket."
        case .disabledByPreferences:
            return "Booking confirmed! Push notifications are turned off in your preferences."
        case .denied, .failed:
            return "Booking confirmed! Tap Download to save your ticket."
        }
    }
}
