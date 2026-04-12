//
//  BusTripDetailView.swift
//  BusTicketBooking
//
//  Created by macos on 4/3/26.
//

import SwiftUI

struct BusTripDetailView: View {

    let trip: BusTrip
    let travelDate: Date

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Bus header
                VStack(spacing: 6) {
                    Text(trip.busName)
                        .font(.title2)
                        .bold()

                    Text(trip.busType)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Theme.primaryColor.opacity(0.15))
                        .foregroundColor(Theme.primaryColor)
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(16)

                // Journey details card
                VStack(spacing: 16) {
                    Text("Journey Details")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .top) {
                        // Departure
                        VStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(trip.departureTime)
                                .font(.headline)
                            Text(trip.source)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        // Duration
                        VStack(spacing: 4) {
                            Text(trip.duration)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .frame(maxWidth: 80)
                            Image(systemName: "bus.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 6)

                        Spacer()

                        // Arrival
                        VStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(trip.arrivalTime)
                                .font(.headline)
                            Text(trip.destination)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(16)

                // Info rows
                VStack(spacing: 0) {
                    DetailRow(icon: "person.2.fill",
                              title: "Available Seats",
                              value: "\(trip.availableSeats)",
                              valueColor: trip.availableSeats <= 5 ? .red : .green)

                    Divider().padding(.leading, 44)

                    DetailRow(icon: "banknote.fill",
                              title: "Ticket Price",
                              value: trip.hasDiscount ? trip.discountedPriceFormatted : trip.priceFormatted,
                              valueColor: Theme.primaryColor)

                    if trip.hasDiscount {
                        Divider().padding(.leading, 44)
                        DetailRow(icon: "tag.fill",
                                  title: "Offer",
                                  value: "\(trip.discount)% OFF (was \(trip.priceFormatted))",
                                  valueColor: .red)
                    }

                    Divider().padding(.leading, 44)

                    DetailRow(icon: "bus.fill",
                              title: "Bus Type",
                              value: trip.busType,
                              valueColor: .primary)
                }
                .background(Theme.cardBackground)
                .cornerRadius(16)

                // Pickup & Dropping Points
                if !trip.pickupPoints.isEmpty || !trip.droppingPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        if !trip.pickupPoints.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Pickup Points", systemImage: "mappin.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                ForEach(trip.pickupPoints, id: \.self) { point in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.green.opacity(0.4))
                                            .frame(width: 6, height: 6)
                                        Text(point)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                        }

                        if !trip.droppingPoints.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Dropping Points", systemImage: "mappin.and.ellipse")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                ForEach(trip.droppingPoints, id: \.self) { point in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.red.opacity(0.4))
                                            .frame(width: 6, height: 6)
                                        Text(point)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(16)
                }

                // Select Seat button
                NavigationLink(destination: SeatSelectionView(trip: trip, travelDate: travelDate)) {
                    Text("Select Seat")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(trip.availableSeats > 0 ? Theme.primaryColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .disabled(trip.availableSeats == 0)
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Detail Row Helper

private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.primaryColor)
                .frame(width: 28)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(valueColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
