//
//  OffersView.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI

struct OffersView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.primaryColor)
                        Text("Offers & Deals")
                            .font(.title2)
                            .bold()
                        Text("Grab the best deals on bus tickets")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    OfferCard(
                        title: "First Ride Discount",
                        description: "Get 15% off on your first bus booking!",
                        code: "FIRST15",
                        gradient: [Theme.primaryColor, Theme.secondaryColor1]
                    )

                    OfferCard(
                        title: "Weekend Special",
                        description: "Flat ৳100 off on weekend travel bookings.",
                        code: "WEEKEND100",
                        gradient: [Theme.secondaryColor2, Theme.secondaryColor1]
                    )

                    OfferCard(
                        title: "Group Booking",
                        description: "Book 4+ seats and save 10% instantly.",
                        code: "GROUP10",
                        gradient: [.orange, Theme.primaryColor]
                    )

                    OfferCard(
                        title: "Night Travel Deal",
                        description: "Save ৳50 on all night bus bookings.",
                        code: "NIGHT50",
                        gradient: [.indigo, Theme.primaryColor]
                    )
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Offers")
        }
    }
}

// MARK: - Offer Card

struct OfferCard: View {
    let title: String
    let description: String
    let code: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            HStack {
                Text("Code: \(code)")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
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
