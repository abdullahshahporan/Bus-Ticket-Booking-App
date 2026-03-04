//
//  HomeView.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI

struct HomeView: View {

    @State private var fromCity = ""
    @State private var toCity = ""
    @State private var selectedDate = Date()

    let routes = [
        Route(from: "Khulna", to: "Dhaka", price: "700 Tk"),
        Route(from: "Khulna", to: "Sylhet", price: "1200 Tk"),
        Route(from: "Dhaka", to: "Chattagram", price: "800 Tk")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    BannerView()

                    VStack(spacing: 15) {

                        TextField("From", text: $fromCity)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)

                        TextField("To", text: $toCity)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)

                        DatePicker("Select Date",
                                   selection: $selectedDate,
                                   displayedComponents: .date)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)

                        Button(action: {}) {
                            Text("Search Buses")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primaryMaroon)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: .gray.opacity(0.2), radius: 10)

                    VStack(alignment: .leading) {
                        Text("Popular Routes")
                            .font(.title3)
                            .bold()
                            .padding(.bottom, 5)

                        ForEach(routes) { route in
                            RouteCardView(route: route)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Bus Booking") 
        }
    }
}
