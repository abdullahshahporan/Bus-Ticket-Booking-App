//
//  BannerView.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI

struct BannerView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Theme.primaryColor, Theme.secondaryColor1]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .offset(x: 130, y: -30)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 60, height: 60)
                .offset(x: 100, y: 40)

            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bus Ticket Booking")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)

                    Text("Book from 64 Districts\nacross Bangladesh")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                }
                Spacer()
                Image(systemName: "bus.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(20)
        }
        .frame(height: 150)
        .cornerRadius(20)
    }
}
