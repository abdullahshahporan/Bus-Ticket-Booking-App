//
//  TicketsView.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI

struct TicketsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var bookingViewModel = BookingViewModel()
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false

    private var userId: String? {
        authViewModel.userSession?.uid
    }

    private var bookingDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    private var departureDateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }


    var body: some View {
        NavigationStack {
            Group {
                if userId == nil {
                    unauthenticatedView
                } else if bookingViewModel.isLoading {
                    loadingView
                } else if let errorMessage = bookingViewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if bookingViewModel.bookings.isEmpty {
                    emptyView
                } else {
                    ticketsList
                }
            }
            .navigationTitle("My Tickets")
            .onAppear {
                fetchTicketsIfNeeded()
            }
            .onChange(of: authViewModel.userSession?.uid) { _ in
                fetchTicketsIfNeeded(force: true)
            }
            .refreshable {
                fetchTicketsIfNeeded(force: true)
            }
            .background(Theme.background)
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL = pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your tickets...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unauthenticatedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 42))
                .foregroundColor(.gray.opacity(0.6))
            Text("Please sign in to view your tickets.")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "ticket")
                .font(.system(size: 46))
                .foregroundColor(.gray.opacity(0.5))
            Text("No tickets yet")
                .font(.headline)
            Text("Book a bus from Home and your tickets will appear here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange.opacity(0.8))
            Text(message)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") {
                fetchTicketsIfNeeded(force: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Theme.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ticketsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(bookingViewModel.bookings) { booking in
                    ticketCard(for: booking)
                }
            }
            .padding()
        }
    }

    private func ticketCard(for booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(booking.busTrip.source) → \(booking.busTrip.destination)")
                        .font(.headline)
                    Text("\(booking.busTrip.busName) • \(booking.busTrip.busType)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    statusBadge(booking.status)
                    if booking.isExpired {
                        expiredBadge
                    }
                }
            }

            Divider()

            HStack {
                Label(departureDisplay(for: booking), systemImage: "clock")
                    .font(.subheadline)
                Spacer()
            }
            .foregroundColor(.secondary)

            HStack {
                Label("Booked \(bookingDateFormatter.string(from: booking.bookingDate))", systemImage: "calendar.badge.clock")
                    .font(.caption)
                Spacer()
            }
            .foregroundColor(.secondary)

            HStack(alignment: .top) {
                Label(booking.seatLabels.joined(separator: ", "), systemImage: "chair")
                    .font(.subheadline)
                Spacer()
                Text("৳\(booking.totalPrice)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(Theme.primaryColor)
            }

            Button {
                Task {
                    await generatePDF(for: booking)
                }
            } label: {
                Label(isGeneratingPDF ? "Preparing..." : "Download Ticket", systemImage: "arrow.down.circle")
                    .font(.subheadline)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Theme.primaryColor.opacity(0.12))
            .foregroundColor(Theme.primaryColor)
            .cornerRadius(10)
            .disabled(isGeneratingPDF)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(14)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }

    @MainActor
    private func generatePDF(for booking: Booking) async {
        guard !isGeneratingPDF else { return }
        isGeneratingPDF = true

        let confirmation = BookingConfirmation(from: booking)
        let name = passengerName
        let phone = passengerPhone

        do {
            let url = try await TicketPDFGenerator.generatePDF(
                confirmation: confirmation,
                passengerName: name,
                passengerPhone: phone
            )
            pdfURL = url
            showShareSheet = true
        } catch {
            pdfURL = nil
        }

        isGeneratingPDF = false
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
        if !profilePhone.isEmpty {
            return profilePhone
        }
        let contactNo = authViewModel.currentUser?.contactNo ?? ""
        if !contactNo.isEmpty {
            return contactNo
        }
        return "Not provided"
    }

    private func statusBadge(_ status: Booking.BookingStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .cornerRadius(6)
    }

    private var expiredBadge: some View {
        Text("Expired")
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.15))
            .foregroundColor(.gray)
            .cornerRadius(6)
    }

    private func departureDisplay(for booking: Booking) -> String {
        if let departureDateTime = booking.departureDateTime {
            return departureDateTimeFormatter.string(from: departureDateTime)
        }
        return booking.busTrip.departureTime
    }

    private func statusColor(_ status: Booking.BookingStatus) -> Color {
        switch status {
        case .confirmed:
            return .green
        case .cancelled:
            return .red
        case .pending:
            return .orange
        }
    }

    private func fetchTicketsIfNeeded(force: Bool = false) {
        guard let userId = userId else { return }
        if force || bookingViewModel.bookings.isEmpty {
            bookingViewModel.fetchUserBookings(userId: userId)
        }
    }
}
