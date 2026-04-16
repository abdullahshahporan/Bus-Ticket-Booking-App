import SwiftUI

struct SoldTicketsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var adminVM = AdminViewModel()

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
        NavigationStack {
            Group {
                if !authViewModel.isAdmin {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Admin access required")
                            .font(.headline)
                        Text("Only admin users can monitor sold tickets.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if adminVM.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading sold tickets...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = adminVM.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task { await adminVM.fetchSoldTickets() }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if adminVM.soldTickets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "ticket")
                            .font(.system(size: 44))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("No sold tickets yet")
                            .font(.headline)
                        Text("Confirmed bookings will be listed here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(adminVM.soldTickets) { ticket in
                                soldTicketCard(ticket)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Sold Tickets")
            .onAppear {
                if authViewModel.isAdmin {
                    Task { await adminVM.fetchSoldTickets() }
                }
            }
            .refreshable {
                if authViewModel.isAdmin {
                    await adminVM.fetchSoldTickets()
                }
            }
        }
    }

    private func soldTicketCard(_ ticket: AdminViewModel.SoldTicketRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ticket.userName)
                        .font(.headline)
                    Text(ticket.userEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ticket.userPhone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("৳\(ticket.totalPrice)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(Theme.primaryColor)
            }

            Divider()

            Label(ticket.busName, systemImage: "bus.fill")
                .font(.subheadline)
            Label(ticket.route, systemImage: "arrow.left.arrow.right")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label("Travel: \(travelFormatter.string(from: ticket.travelDate))", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Label("Booked: \(bookingFormatter.string(from: ticket.bookingDate))", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !ticket.seatLabels.isEmpty {
                Label(ticket.seatLabels.joined(separator: ", "), systemImage: "chair")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(14)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}
