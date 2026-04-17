//
//  ManageBusesView.swift
//  BusTicketBooking
//

import SwiftUI

@MainActor
struct ManageBusesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var adminVM = AdminViewModel()
    @State private var searchText = ""
    @State private var busToDelete: BusTrip?
    @State private var showDeleteAlert = false

    private var isOperatorMode: Bool {
        authViewModel.currentUser?.isOperator == true
    }

    private var filteredBuses: [BusTrip] {
        if searchText.isEmpty {
            return adminVM.busTrips
        }

        return adminVM.busTrips.filter {
            $0.busName.localizedCaseInsensitiveContains(searchText) ||
            $0.source.localizedCaseInsensitiveContains(searchText) ||
            $0.destination.localizedCaseInsensitiveContains(searchText) ||
            ($0.operatorDisplayName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if adminVM.isLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(isOperatorMode ? "Loading your buses..." : "Loading buses...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredBuses.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bus.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.4))
                        Text(isOperatorMode ? "No buses in your fleet" : "No buses found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(isOperatorMode ? "Add buses from the Add Bus tab to start managing your routes." : "Add buses from the Add Bus tab.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredBuses) { trip in
                                ManageBusCard(
                                    trip: trip,
                                    showsOperatorOwner: !isOperatorMode
                                ) {
                                    busToDelete = trip
                                    showDeleteAlert = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle(isOperatorMode ? "My Buses" : "Manage Buses")
            .searchable(
                text: $searchText,
                prompt: isOperatorMode ? "Search your buses..." : "Search buses..."
            )
            .onAppear {
                Task { await adminVM.fetchAllBuses(for: authViewModel.currentUser) }
            }
            .refreshable {
                await adminVM.fetchAllBuses(for: authViewModel.currentUser)
            }
            .alert("Delete Bus", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let bus = busToDelete {
                        Task {
                            let _ = await adminVM.deleteBus(
                                trip: bus,
                                currentUser: authViewModel.currentUser
                            )
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(busToDelete?.busName ?? "this bus")?")
            }
        }
    }
}

// MARK: - Manage Bus Card

struct ManageBusCard: View {
    let trip: BusTrip
    let showsOperatorOwner: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.busName)
                        .font(.headline)
                    Text(trip.busType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.primaryColor.opacity(0.15))
                        .foregroundColor(Theme.primaryColor)
                        .cornerRadius(4)
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.source)
                        .font(.subheadline)
                        .bold()
                    Text(trip.departureTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(trip.destination)
                        .font(.subheadline)
                        .bold()
                    Text(trip.arrivalTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            HStack {
                Label("\(trip.availableSeats) seats", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if trip.hasDiscount {
                        Text("\(trip.discount)% OFF")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.red)
                        Text(trip.priceFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .strikethrough()
                    }
                    Text(trip.hasDiscount ? trip.discountedPriceFormatted : trip.priceFormatted)
                        .font(.headline)
                        .foregroundColor(Theme.primaryColor)
                }
            }

            if showsOperatorOwner, let operatorDisplayName = trip.operatorDisplayName {
                Label("Operator: \(operatorDisplayName)", systemImage: "person.text.rectangle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !trip.pickupPoints.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Pickup: \(trip.pickupPoints.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !trip.droppingPoints.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text("Dropping: \(trip.droppingPoints.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(14)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}
