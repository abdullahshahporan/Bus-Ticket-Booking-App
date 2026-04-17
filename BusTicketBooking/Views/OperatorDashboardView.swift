//
//  OperatorDashboardView.swift
//  BusTicketBooking
//

import SwiftUI

@MainActor
struct OperatorDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isOperator {
                TabView {
                    OperatorHomeView()
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Overview")
                        }

                    AddBusView()
                        .tabItem {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Bus")
                        }

                    ManageBusesView()
                        .tabItem {
                            Image(systemName: "bus.fill")
                            Text("Fleet")
                        }

                    OperatorRevenueView()
                        .tabItem {
                            Image(systemName: "banknote.fill")
                            Text("Revenue")
                        }

                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.circle.fill")
                            Text("Profile")
                        }
                }
            } else {
                RoleAccessFallback(
                    title: "Operator access required",
                    message: "Please sign in with a bus operator account to manage fleet and revenue."
                ) {
                    authViewModel.signOut()
                }
            }
        }
        .accentColor(Theme.primaryColor)
    }
}

@MainActor
struct OperatorHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var adminVM = AdminViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    operatorHero
                    summaryGrid
                    fleetSection
                    recentSalesSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Theme.background)
            .navigationTitle("Operator")
            .onAppear {
                Task { await refreshOverview() }
            }
            .refreshable {
                await refreshOverview()
            }
        }
    }

    private var operatorHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(authViewModel.currentUser?.fullName ?? "Bus Operator")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text(authViewModel.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.white)
            }

            Text("Add buses to any route, manage your fleet, and keep track of daily and total revenue from one workspace.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [Theme.primaryColor, Theme.secondaryColor1],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.top, 16)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCard(
                icon: "bus.fill",
                title: "Managed Buses",
                value: "\(adminVM.busTrips.count)",
                subtitle: "Active fleet",
                color: Theme.primaryColor
            )
            MetricCard(
                icon: "map.fill",
                title: "Routes",
                value: "\(adminVM.revenueOverview.totalRoutes)",
                subtitle: "Covered routes",
                color: Theme.secondaryColor1
            )
            MetricCard(
                icon: "sun.max.fill",
                title: "Today",
                value: "৳\(adminVM.revenueOverview.todayRevenue)",
                subtitle: "Today's revenue",
                color: Theme.secondaryColor2
            )
            MetricCard(
                icon: "banknote.fill",
                title: "Total Revenue",
                value: "৳\(adminVM.revenueOverview.totalRevenue)",
                subtitle: "Lifetime total",
                color: .orange
            )
        }
    }

    @ViewBuilder
    private var fleetSection: some View {
        if let error = adminVM.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }

        if adminVM.busTrips.isEmpty {
            EmptyStateCard(
                icon: "bus",
                title: "No buses added yet",
                message: "Use the Add Bus tab to publish your first route and start tracking operator revenue."
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fleet Snapshot")
                    .font(.headline)

                ForEach(adminVM.busTrips.prefix(4)) { trip in
                    AdminBusRow(trip: trip)
                }
            }
        }
    }

    @ViewBuilder
    private var recentSalesSection: some View {
        if !adminVM.revenueOverview.recentTransactions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Sales")
                    .font(.headline)

                ForEach(adminVM.revenueOverview.recentTransactions.prefix(3)) { transaction in
                    RevenueTransactionRow(transaction: transaction)
                }
            }
        }
    }

    private func refreshOverview() async {
        await adminVM.fetchAllBuses(for: authViewModel.currentUser)
        await adminVM.fetchRevenueOverview(for: authViewModel.currentUser)
        await authViewModel.fetchUserProfile()
    }
}

@MainActor
struct OperatorRevenueView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var adminVM = AdminViewModel()

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    summaryCards
                    dailyRevenueSection
                    revenueByBusSection
                    recentTransactionsSection
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Revenue")
            .onAppear {
                Task { await refreshRevenue() }
            }
            .refreshable {
                await refreshRevenue()
            }
        }
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            if let error = adminVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                MetricCard(
                    icon: "banknote.fill",
                    title: "Total Revenue",
                    value: "৳\(adminVM.revenueOverview.totalRevenue)",
                    subtitle: "All confirmed sales",
                    color: Theme.primaryColor
                )
                MetricCard(
                    icon: "calendar",
                    title: "Today",
                    value: "৳\(adminVM.revenueOverview.todayRevenue)",
                    subtitle: "Revenue earned today",
                    color: Theme.secondaryColor1
                )
            }

            HStack(spacing: 12) {
                MetricCard(
                    icon: "ticket.fill",
                    title: "Bookings",
                    value: "\(adminVM.revenueOverview.totalBookings)",
                    subtitle: "Confirmed bookings",
                    color: Theme.secondaryColor2
                )
                MetricCard(
                    icon: "bus.fill",
                    title: "Buses",
                    value: "\(adminVM.revenueOverview.totalBuses)",
                    subtitle: "Your total fleet",
                    color: .orange
                )
            }
        }
    }

    private var dailyRevenueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Revenue")
                .font(.headline)

            if adminVM.revenueOverview.dailyBreakdown.isEmpty {
                EmptyStateCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No daily revenue yet",
                    message: "Revenue by day will appear here after bookings are confirmed for your buses."
                )
            } else {
                ForEach(adminVM.revenueOverview.dailyBreakdown.prefix(7)) { day in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dayFormatter.string(from: day.date))
                                .font(.subheadline)
                                .bold()
                            Text("\(day.bookings) booking\(day.bookings == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("৳\(day.revenue)")
                            .font(.headline)
                            .foregroundColor(Theme.primaryColor)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(14)
                }
            }
        }
    }

    private var revenueByBusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revenue By Bus")
                .font(.headline)

            if adminVM.revenueOverview.busBreakdown.isEmpty {
                EmptyStateCard(
                    icon: "bus",
                    title: "No bus revenue yet",
                    message: "Each bus will appear here with its bookings, sold seats, and total earnings."
                )
            } else {
                ForEach(adminVM.revenueOverview.busBreakdown) { record in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.busName)
                                    .font(.headline)
                                Text(record.route)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("৳\(record.revenue)")
                                .font(.title3)
                                .bold()
                                .foregroundColor(Theme.primaryColor)
                        }

                        HStack {
                            Label("\(record.bookings) bookings", systemImage: "ticket.fill")
                            Spacer()
                            Label("\(record.soldSeats) seats", systemImage: "chair.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(16)
                }
            }
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)

            if adminVM.revenueOverview.recentTransactions.isEmpty {
                EmptyStateCard(
                    icon: "clock.arrow.circlepath",
                    title: "No recent transactions",
                    message: "Confirmed sales will show up here with route and seat details."
                )
            } else {
                ForEach(adminVM.revenueOverview.recentTransactions) { transaction in
                    RevenueTransactionRow(transaction: transaction)
                }
            }
        }
    }

    private func refreshRevenue() async {
        await adminVM.fetchRevenueOverview(for: authViewModel.currentUser)
    }
}
