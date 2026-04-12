//
//  DistrictPickerView.swift
//  BusTicketBooking
//

import SwiftUI

struct DistrictPickerView: View {
    let title: String
    @Binding var selectedDistrict: String
    @ObservedObject var districtService: DistrictService
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var filteredDistricts: [District] {
        if searchText.isEmpty {
            return districtService.districts
        }
        return districtService.districts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bnName.contains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if districtService.isLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading districts...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = districtService.errorMessage {
                    VStack(spacing: 14) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task { await districtService.fetchDistricts() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Theme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredDistricts) { district in
                        Button {
                            selectedDistrict = district.name
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(district.name)
                                        .foregroundColor(.primary)
                                    Text(district.bnName)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if selectedDistrict == district.name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.primaryColor)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search district...")
                }
            }
            .background(Theme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if districtService.districts.isEmpty {
                    Task { await districtService.fetchDistricts() }
                }
            }
        }
    }
}
