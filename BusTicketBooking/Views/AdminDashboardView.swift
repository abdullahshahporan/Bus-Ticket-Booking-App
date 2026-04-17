//
//  AdminDashboardView.swift
//  BusTicketBooking
//

import SwiftUI

@MainActor
struct AdminDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAdmin {
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
            } else {
                RoleAccessFallback(
                    title: "Admin access required",
                    message: "Please sign in with an authorized admin account."
                ) {
                    authViewModel.signOut()
                }
            }
        }
        .accentColor(Theme.primaryColor)
    }
}

@MainActor
struct AdminHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var adminVM = AdminViewModel()
    @State private var showCreateOperatorSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    adminHeader
                    statsGrid
                    operatorSection
                    recentBusesSection
                }
                .padding(.bottom, 20)
            }
            .background(Theme.background)
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showCreateOperatorSheet) {
                CreateOperatorSheet(adminVM: adminVM)
            }
            .onAppear {
                Task { await refreshDashboard() }
            }
            .refreshable {
                await refreshDashboard()
            }
        }
    }

    private var adminHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 50))
                .foregroundColor(Theme.primaryColor)
            Text("Admin Panel")
                .font(.title)
                .bold()
            Text("Manage your fleet, operator access, and ticket sales")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var statsGrid: some View {
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
    }

    private var operatorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bus Operators")
                        .font(.headline)
                    Text("Create operator logins with email and password. Email verification is not required for them right now.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    adminVM.errorMessage = nil
                    adminVM.successMessage = nil
                    showCreateOperatorSheet = true
                } label: {
                    Label("Add Operator", systemImage: "person.badge.plus")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.primaryColor.opacity(0.12))
                .foregroundColor(Theme.primaryColor)
                .cornerRadius(12)
            }

            HStack(spacing: 12) {
                MetricCard(
                    icon: "person.3.fill",
                    title: "Operators",
                    value: "\(adminVM.totalOperators)",
                    subtitle: "Active accounts",
                    color: Theme.primaryColor
                )
                MetricCard(
                    icon: "checkmark.seal.fill",
                    title: "Access Mode",
                    value: "Email + Pass",
                    subtitle: "No verify needed",
                    color: Theme.secondaryColor1
                )
            }

            if let error = adminVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if let success = adminVM.successMessage {
                Text(success)
                    .font(.caption)
                    .foregroundColor(.green)
            }

            if adminVM.operatorAccounts.isEmpty {
                EmptyStateCard(
                    icon: "person.badge.key.fill",
                    title: "No operator accounts yet",
                    message: "Create the first operator so they can log in, publish buses, and monitor revenue professionally."
                )
            } else {
                ForEach(adminVM.operatorAccounts.prefix(4)) { account in
                    OperatorAccountRow(account: account)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var recentBusesSection: some View {
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

    private var uniqueRouteCount: Int {
        let routes = Set(adminVM.busTrips.map { "\($0.source)-\($0.destination)" })
        return routes.count
    }

    private func refreshDashboard() async {
        await adminVM.fetchAllBuses()
        await adminVM.fetchStats()
        await adminVM.fetchOperatorAccounts()
        await authViewModel.fetchUserProfile()
    }
}
