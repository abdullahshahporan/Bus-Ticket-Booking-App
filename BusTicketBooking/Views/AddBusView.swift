//
//  AddBusView.swift
//  BusTicketBooking
//

import SwiftUI

struct AddBusView: View {
    @StateObject private var adminVM = AdminViewModel()
    @StateObject private var districtService = DistrictService.shared

    @State private var busName = ""
    @State private var selectedSource = ""
    @State private var selectedDestination = ""
    @State private var departureTime = Date()
    @State private var arrivalTime = Date()
    @State private var ticketPrice = ""
    @State private var busType = "AC"
    @State private var pickupPoints: [String] = [""]
    @State private var droppingPoints: [String] = [""]

    @State private var showSuccessAlert = false

    private let busTypes = ["AC", "Non-AC", "Sleeper", "Double Decker"]

    private var isFormValid: Bool {
        !busName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedSource.isEmpty &&
        !selectedDestination.isEmpty &&
        selectedSource != selectedDestination &&
        (Int(ticketPrice) ?? 0) > 0
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.primaryColor)
                        Text("Add New Bus")
                            .font(.title2)
                            .bold()
                    }
                    .padding(.top, 10)

                    // Bus Info Section
                    VStack(spacing: 16) {
                        sectionHeader("Bus Information")

                        inputField(icon: "bus.fill", placeholder: "Bus Name (e.g. Green Line)", text: $busName)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bus Type")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Picker("Bus Type", selection: $busType) {
                                ForEach(busTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ticket Price (৳)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack {
                                Image(systemName: "banknote.fill")
                                    .foregroundColor(Theme.primaryColor)
                                TextField("Enter price", text: $ticketPrice)
                                    #if os(iOS)
                                    .keyboardType(.numberPad)
                                    #endif
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(16)

                    // Route Section
                    VStack(spacing: 16) {
                        sectionHeader("Route")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("From District")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            DistrictAutocompleteField(
                                label: "Select departure district",
                                icon: "circle.fill",
                                iconColor: .green,
                                selectedDistrict: $selectedSource,
                                districtService: districtService
                            )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("To District")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            DistrictAutocompleteField(
                                label: "Select destination district",
                                icon: "circle.fill",
                                iconColor: .red,
                                selectedDistrict: $selectedDestination,
                                districtService: districtService
                            )
                        }
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(16)

                    // Time Section
                    VStack(spacing: 16) {
                        sectionHeader("Schedule")

                        DatePicker("Departure Time", selection: $departureTime, displayedComponents: .hourAndMinute)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)

                        DatePicker("Arrival Time", selection: $arrivalTime, displayedComponents: .hourAndMinute)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(16)

                    // Pickup Points
                    dynamicPointsSection(
                        title: "Pickup Points",
                        icon: "mappin.circle.fill",
                        points: $pickupPoints
                    )

                    // Dropping Points
                    dynamicPointsSection(
                        title: "Dropping Points",
                        icon: "mappin.and.ellipse",
                        points: $droppingPoints
                    )

                    // Error Message
                    if let error = adminVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    // Add Bus Button
                    Button {
                        Task { await addBus() }
                    } label: {
                        if adminVM.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primaryColor)
                                .cornerRadius(14)
                        } else {
                            Text("Add Bus")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? Theme.primaryColor : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .disabled(!isFormValid || adminVM.isLoading)
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Add Bus")
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") { resetForm() }
            } message: {
                Text(adminVM.successMessage ?? "Bus added successfully!")
            }
            .onAppear {
                Task { await districtService.fetchDistricts() }
            }
        }
    }

    // MARK: - Actions

    private func addBus() async {
        let success = await adminVM.addBus(
            busName: busName.trimmingCharacters(in: .whitespaces),
            source: selectedSource,
            destination: selectedDestination,
            departureTime: timeFormatter.string(from: departureTime),
            arrivalTime: timeFormatter.string(from: arrivalTime),
            ticketPrice: Int(ticketPrice) ?? 0,
            busType: busType,
            pickupPoints: pickupPoints,
            droppingPoints: droppingPoints
        )
        if success {
            showSuccessAlert = true
        }
    }

    private func resetForm() {
        busName = ""
        selectedSource = ""
        selectedDestination = ""
        departureTime = Date()
        arrivalTime = Date()
        ticketPrice = ""
        busType = "AC"
        pickupPoints = [""]
        droppingPoints = [""]
        adminVM.errorMessage = nil
        adminVM.successMessage = nil
    }

    // MARK: - UI Components

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func inputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.primaryColor)
            TextField(placeholder, text: text)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func dynamicPointsSection(
        title: String,
        icon: String,
        points: Binding<[String]>
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.primaryColor)
                Text(title)
                    .font(.headline)
                Spacer()
                Button {
                    points.wrappedValue.append("")
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.primaryColor)
                }
            }

            ForEach(points.wrappedValue.indices, id: \.self) { index in
                HStack {
                    TextField("Point \(index + 1)", text: points[index])
                        .autocorrectionDisabled()
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    if points.wrappedValue.count > 1 {
                        Button {
                            points.wrappedValue.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
}
