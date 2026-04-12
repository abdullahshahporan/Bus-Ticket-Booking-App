//
//  AdminDashboardView.swift
//  BusTicketBooking
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            AdminHomeView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Dashboard")
                }

            AddBusView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Bus")
                }

            ManageBusesView()
                .tabItem {
                    Image(systemName: "bus.fill")
                    Text("Buses")
                }

            SoldTicketsView()
                .tabItem {
                    Image(systemName: "ticket.fill")
                    Text("Sold")
                }

            AdminProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
        }
        .accentColor(Theme.primaryColor)
    }
}

// MARK: - Admin Home (Dashboard Stats)

struct AdminHomeView: View {
    @StateObject private var adminVM = AdminViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.primaryColor)
                        Text("Admin Panel")
                            .font(.title)
                            .bold()
                        Text("Manage your bus fleet")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            icon: "bus.fill",
                            title: "Total Buses",
                            value: "\(adminVM.busTrips.count)",
                            color: Theme.primaryColor
                        )
                        StatCard(
                            icon: "ticket.fill",
                            title: "Bookings",
                            value: "\(adminVM.totalBookings)",
                            color: Theme.secondaryColor1
                        )
                        StatCard(
                            icon: "person.2.fill",
                            title: "Users",
                            value: "\(adminVM.totalUsers)",
                            color: Theme.secondaryColor2
                        )
                        StatCard(
                            icon: "map.fill",
                            title: "Routes",
                            value: "\(uniqueRouteCount)",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Recent Buses
                    if !adminVM.busTrips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Buses")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(adminVM.busTrips.prefix(5)) { trip in
                                AdminBusRow(trip: trip)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Theme.background)
            .navigationTitle("Dashboard")
            .onAppear {
                Task {
                    await adminVM.fetchAllBuses()
                    await adminVM.fetchStats()
                }
            }
            .refreshable {
                await adminVM.fetchAllBuses()
                await adminVM.fetchStats()
            }
        }
    }

    private var uniqueRouteCount: Int {
        let routes = Set(adminVM.busTrips.map { "\($0.source)-\($0.destination)" })
        return routes.count
    }
}

// MARK: - Stat Card

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

// MARK: - Admin Bus Row

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

// MARK: - Admin Settings

struct AdminSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.primaryColor)
                    Text("Admin Account")
                        .font(.title2)
                        .bold()
                    Text(authViewModel.currentUser?.email ?? "admin@gmail.com")
                        .foregroundColor(.gray)
                }

                Spacer()

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
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Theme.background)
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}
