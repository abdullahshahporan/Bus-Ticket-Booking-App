import SwiftUI
import FirebaseAuth

struct SeatSelectionView: View {

    let trip: BusTrip
    let travelDate: Date

    private let columns = 4
    private let totalRows = 10

    @State private var selectedSeats: Set<Int> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var bookingConfirmation: BookingConfirmation?
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                VStack(spacing: 4) {
                    Text(trip.busName)
                        .font(.headline)
                    Text("\(trip.source) → \(trip.destination)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.cardBackground)

                ScrollView {
                    VStack(spacing: 20) {

                        HStack(spacing: 20) {
                            legendItem(color: .gray.opacity(0.25), label: "Available")
                            legendItem(color: Theme.primaryColor, label: "Selected")
                            legendItem(color: Theme.dangerColor.opacity(0.4), label: "Booked")
                        }
                        .padding(.top)

                        VStack(spacing: 10) {
                            HStack {
                                Spacer()
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                            .padding(.bottom, 4)

                            ForEach(0..<totalRows, id: \.self) { row in
                                HStack(spacing: 8) {
                                    seatButton(seatIndex: row * columns + 0)
                                    seatButton(seatIndex: row * columns + 1)

                                    Spacer()
                                        .frame(width: 28)

                                    seatButton(seatIndex: row * columns + 2)
                                    seatButton(seatIndex: row * columns + 3)
                                }
                            }
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)

                        if !selectedSeats.isEmpty {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Selected Seats")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(selectedSeats.sorted().map { SeatHelper.indexToLabel($0) }.joined(separator: ", "))
                                        .font(.subheadline)
                                        .bold()
                                }
                                HStack {
                                    Text("Total Price")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("৳\(selectedSeats.count * trip.ticketPrice)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(Theme.primaryColor)
                                }
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                        }

                        if let errorMessage = errorMessage {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }

                Button(action: goToPreview) {
                    Text(selectedSeats.isEmpty
                        ? "Select a Seat"
                        : "Preview Ticket  •  ৳\(selectedSeats.count * trip.ticketPrice)")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedSeats.isEmpty ? Color.gray : Theme.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(selectedSeats.isEmpty)
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Select Seat")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showConfirmation) {
                if let bookingConfirmation = bookingConfirmation {
                    BookingConfirmationView(confirmation: bookingConfirmation)
                } else {
                    Text("Loading...")
                }
            }
        }
    }

    private func goToPreview() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }

        let selectedIndices = Array(selectedSeats).sorted()
        let totalPrice = selectedIndices.count * trip.ticketPrice

        bookingConfirmation = BookingConfirmation(
            id: UUID().uuidString,
            userId: userId,
            trip: trip,
            seatIndices: selectedIndices,
            seatLabels: selectedIndices.map { SeatHelper.indexToLabel($0) },
            totalPrice: totalPrice,
            bookingDate: Date(),
            travelDate: travelDate
        )

        showConfirmation = true
    }

    private func isSeatBooked(_ index: Int) -> Bool {
        return SeatHelper.isSeatBooked(index, in: trip.seatMatrix)
    }

    @ViewBuilder
    private func seatButton(seatIndex: Int) -> some View {
        let booked = isSeatBooked(seatIndex)
        let selected = selectedSeats.contains(seatIndex)
        let seatLabel = SeatHelper.indexToLabel(seatIndex)

        Button {
            if !booked {
                if selected {
                    selectedSeats.remove(seatIndex)
                } else {
                    selectedSeats.insert(seatIndex)
                }
            }
        } label: {
            Text(seatLabel)
                .font(.caption)
                .bold()
                .frame(width: 42, height: 42)
                .background(
                    booked ? Theme.dangerColor.opacity(0.4)
                    : selected ? Theme.primaryColor
                    : Color.gray.opacity(0.25)
                )
                .foregroundColor(booked || selected ? .white : .primary)
                .cornerRadius(8)
        }
        .disabled(booked)
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 18, height: 18)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
