//
//  OffersView.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI

@MainActor
struct OffersView: View {
    @StateObject private var viewModel = BusTripViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading offers...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        Button("Retry") {
                            viewModel.fetchOfferTrips()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.trips.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tag.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("No offers available")
                            .font(.headline)
                        Text("Discounted trips will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.trips) { trip in
                                NavigationLink(destination: BusTripDetailView(trip: trip, travelDate: Date())) {
                                    OfferTripCard(trip: trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Offers")
            .onAppear {
                if viewModel.trips.isEmpty {
                    viewModel.fetchOfferTrips()
                }
            }
            .refreshable {
                viewModel.fetchOfferTrips()
            }
        }
    }
}

// MARK: - Offer Trip Card

struct OfferTripCard: View {
    let trip: BusTrip

    private var gradient: [Color] {
        if trip.discount >= 30 {
            return [Color(red: 0.04, green: 0.33, blue: 0.65), Color(red: 0.00, green: 0.60, blue: 0.72)]
        }
        if trip.discount >= 15 {
            return [Color(red: 0.12, green: 0.45, blue: 0.20), Color(red: 0.26, green: 0.67, blue: 0.25)]
        }
        return [Color(red: 0.52, green: 0.20, blue: 0.12), Color(red: 0.80, green: 0.39, blue: 0.16)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(trip.busName)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(trip.discount)% OFF")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }

            Text("\(trip.source) → \(trip.destination)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))

            HStack {
                Text(trip.priceFormatted)
                    .font(.caption)
                    .strikethrough()
                    .foregroundColor(.white.opacity(0.8))
                Text(trip.discountedPriceFormatted)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradient),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8)
    }
}
