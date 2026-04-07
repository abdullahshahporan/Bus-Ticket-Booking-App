//
//  BusListView.swift
//  BusTicketBooking
//
//  Created by macos on 4/3/26.
//

import SwiftUI

struct BusListView: View {

    let fromCity: String
    let toCity: String
    let travelDate: Date

    @StateObject private var viewModel = BusTripViewModel()

    private var dateFormatted: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: travelDate)
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header summary
            VStack(spacing: 4) {
                Text("\(fromCity) → \(toCity)")
                    .font(.headline)
                Text(dateFormatted)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if !viewModel.isLoading {
                    Text("\(viewModel.trips.count) bus\(viewModel.trips.count == 1 ? "" : "es") found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.cardBackground)

            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("Searching for buses...")
                        .foregroundColor(.gray)
                }
                Spacer()

            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange.opacity(0.7))
                    Text(error)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        viewModel.fetchTrips(from: fromCity, to: toCity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Theme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                Spacer()

            } else if viewModel.trips.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bus.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No buses found for this route.")
                        .foregroundColor(.gray)
                    Text("Try a different source or destination.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.trips) { trip in
                            NavigationLink(destination: BusTripDetailView(trip: trip, travelDate: travelDate)) {
                                BusCardView(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Theme.background)
        .navigationTitle("Available Buses")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchTrips(from: fromCity, to: toCity)
        }
    }
}
