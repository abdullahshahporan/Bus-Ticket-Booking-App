//
//  AdminDashboardComponents.swift
//  BusTicketBooking
//

import SwiftUI

struct RoleAccessFallback: View {
    let title: String
    let message: String
    let onSignOut: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 42))
                .foregroundColor(.orange)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Go to Sign In") {
                onSignOut()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: color.opacity(0.1), radius: 8)
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: color.opacity(0.08), radius: 6)
    }
}

struct AdminBusRow: View {
    let trip: BusTrip

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bus.fill")
                .font(.title3)
                .foregroundColor(Theme.primaryColor)
                .frame(width: 40, height: 40)
                .background(Theme.primaryColor.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(trip.busName)
                    .font(.subheadline)
                    .bold()
                Text("\(trip.source) → \(trip.destination)")
                    .font(.caption)
                    .foregroundColor(.gray)
                if let operatorDisplayName = trip.operatorDisplayName {
                    Text(operatorDisplayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if trip.hasDiscount {
                    Text("\(trip.discount)% OFF")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.red)
                }
                Text(trip.hasDiscount ? trip.discountedPriceFormatted : trip.priceFormatted)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(Theme.primaryColor)
                Text("\(trip.availableSeats) seats")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }
}

struct OperatorAccountRow: View {
    let account: AdminViewModel.OperatorAccountSummary

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(account.fullName)
                        .font(.headline)
                    Text(account.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("৳\(account.revenue)")
                    .font(.headline)
                    .foregroundColor(Theme.primaryColor)
            }

            HStack {
                Label("\(account.busCount) buses", systemImage: "bus.fill")
                Spacer()
                Label("\(account.bookingCount) bookings", systemImage: "ticket.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Text("Created \(formatter.string(from: account.createdAt))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct RevenueTransactionRow: View {
    let transaction: AdminViewModel.RevenueTransaction

    private let bookingFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let travelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.busName)
                        .font(.headline)
                    Text(transaction.route)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("৳\(transaction.amount)")
                    .font(.headline)
                    .foregroundColor(Theme.primaryColor)
            }

            HStack {
                Label("Booked: \(bookingFormatter.string(from: transaction.bookingDate))", systemImage: "clock")
                Spacer()
                Label("Travel: \(travelFormatter.string(from: transaction.travelDate))", systemImage: "calendar")
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            if !transaction.seatLabels.isEmpty {
                Label(transaction.seatLabels.joined(separator: ", "), systemImage: "chair")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(14)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundColor(.gray.opacity(0.7))
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
}
