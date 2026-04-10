//
//  SeatLayoutPDFView.swift
//  BusTicketBooking
//
//  Created by GitHub Copilot.
//

import SwiftUI

struct SeatLayoutPDFView: View {
    let bookedSeatIndices: Set<Int>

    private let columns = 4
    private let totalRows = 10

    var body: some View {
        VStack(spacing: 16) {
            Text("Seat Layout")
                .font(.title2)
                .bold()

            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Image(systemName: "steeringwheel")
                        .font(.title3)
                        .foregroundColor(.gray)
                }

                ForEach(0..<totalRows, id: \.self) { row in
                    HStack(spacing: 8) {
                        seatCell(index: row * columns + 0)
                        seatCell(index: row * columns + 1)

                        Spacer()
                            .frame(width: 28)

                        seatCell(index: row * columns + 2)
                        seatCell(index: row * columns + 3)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(16)
        .background(Color.white)
    }

    private func seatCell(index: Int) -> some View {
        let isBooked = bookedSeatIndices.contains(index)
        let seatLabel = SeatHelper.indexToLabel(index)

        return Text(seatLabel)
            .font(.caption2)
            .bold()
            .frame(width: 32, height: 32)
            .background(isBooked ? Color.green : Color.gray.opacity(0.2))
            .foregroundColor(isBooked ? .white : .black)
            .cornerRadius(6)
    }
}
