//
//  MoreView.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI

struct MoreView: View {

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("About")) {
                    LabeledContent("App Version", value: "1.0.0")
                    LabeledContent("Build",       value: "1")
                }

                Section(header: Text("Info")) {
                    Label("Bus data is managed via Admin Panel", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("More")
        }
    }
}
