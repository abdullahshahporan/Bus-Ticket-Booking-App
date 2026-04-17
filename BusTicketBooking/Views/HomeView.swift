//
//  HomeView.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI

@MainActor
struct HomeView: View {

    @State private var fromCity = ""
    @State private var toCity = ""
    @State private var selectedDate = Date()
    @State private var isReturnTrip = false
    @State private var returnDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var navigateToResults = false
    @State private var tripType: TripType = .oneWay

    @StateObject private var routeViewModel = RouteViewModel()
    @StateObject private var districtService = DistrictService.shared

    enum TripType: String, CaseIterable {
        case oneWay = "One Way"
        case roundTrip = "Round Trip"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    BannerView()

                    // MARK: - Search Card
                    VStack(spacing: 15) {

                        // Trip Type Selector
                        Picker("Trip Type", selection: $tripType) {
                            ForEach(TripType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: tripType) { newValue in
                            isReturnTrip = newValue == .roundTrip
                        }

                        // From District (Inline Autocomplete)
                        DistrictAutocompleteField(
                            label: "From District",
                            icon: "circle.fill",
                            iconColor: .green,
                            selectedDistrict: $fromCity,
                            districtService: districtService
                        )

                        // Swap button
                        Button {
                            let temp = fromCity
                            fromCity = toCity
                            toCity = temp
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.primaryColor)
                        }
                        .disabled(fromCity.isEmpty && toCity.isEmpty)

                        // To District (Inline Autocomplete)
                        DistrictAutocompleteField(
                            label: "To District",
                            icon: "circle.fill",
                            iconColor: .red,
                            selectedDistrict: $toCity,
                            districtService: districtService
                        )

                        // Travel Date
                        DatePicker("Departure Date",
                                   selection: $selectedDate,
                                   in: Date()...,
                                   displayedComponents: .date)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)

                        // Return Date (if round trip)
                        if isReturnTrip {
                            DatePicker("Return Date",
                                       selection: $returnDate,
                                       in: selectedDate...,
                                       displayedComponents: .date)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Button(action: {
                            navigateToResults = true
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search Buses")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (fromCity.isEmpty || toCity.isEmpty)
                                ? Color.gray
                                : Theme.primaryColor
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(fromCity.isEmpty || toCity.isEmpty)
                        .navigationDestination(isPresented: $navigateToResults) {
                            BusListView(
                                fromCity: fromCity,
                                toCity: toCity,
                                travelDate: selectedDate,
                                isReturnTrip: isReturnTrip,
                                returnDate: returnDate
                            )
                        }

                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: .gray.opacity(0.15), radius: 10)
                    .animation(.easeInOut(duration: 0.25), value: isReturnTrip)

                    // MARK: - Popular Routes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Popular Routes")
                            .font(.title3)
                            .bold()
                            .padding(.bottom, 2)

                        if routeViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if let err = routeViewModel.errorMessage {
                            Text(err)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal, 4)
                        } else if routeViewModel.popularRoutes.isEmpty {
                            Text("No routes available yet.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .padding(.horizontal, 4)
                        } else {
                            ForEach(routeViewModel.popularRoutes) { route in
                                RouteCardView(route: route) {
                                    fromCity = route.from
                                    toCity = route.to
                                    navigateToResults = true
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Bus Booking")
            .onAppear {
                Task { await districtService.fetchDistricts() }
                if routeViewModel.popularRoutes.isEmpty {
                    routeViewModel.fetchPopularRoutes()
                }
            }
        }
    }
}
