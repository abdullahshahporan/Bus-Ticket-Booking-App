//
//  DistrictAutocompleteField.swift
//  BusTicketBooking
//

import SwiftUI

@MainActor
struct DistrictAutocompleteField: View {
    let label: String
    let icon: String
    let iconColor: Color
    @Binding var selectedDistrict: String
    @ObservedObject var districtService: DistrictService

    @State private var searchText = ""
    @State private var isExpanded = false
    @FocusState private var isFocused: Bool

    private var filteredDistricts: [District] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return districtService.districts.filter {
            $0.name.lowercased().hasPrefix(query) ||
            $0.bnName.contains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text field row
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(iconColor)

                TextField(label, text: $searchText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($isFocused)
                    .onChange(of: searchText) { newValue in
                        if newValue != selectedDistrict {
                            isExpanded = !newValue.isEmpty
                            // Clear selection if user is typing something different
                            if !districtService.districts.contains(where: { $0.name == newValue }) {
                                selectedDistrict = ""
                            }
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        selectedDistrict = ""
                        isExpanded = false
                        isFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }

                if !selectedDistrict.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? Theme.primaryColor.opacity(0.5) : Color.gray.opacity(0.2),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )

            // Dropdown suggestions
            if isExpanded && !filteredDistricts.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredDistricts.prefix(8)) { district in
                            Button {
                                selectDistrict(district)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(Theme.primaryColor.opacity(0.6))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(highlightedName(district.name))
                                        Text(district.bnName)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if district.id != filteredDistricts.prefix(8).last?.id {
                                Divider().padding(.leading, 38)
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
                .background(Theme.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .onAppear {
            // Sync initial value
            if !selectedDistrict.isEmpty {
                searchText = selectedDistrict
            }
            if districtService.districts.isEmpty {
                Task { await districtService.fetchDistricts() }
            }
        }
    }

    private func selectDistrict(_ district: District) {
        selectedDistrict = district.name
        searchText = district.name
        isExpanded = false
        isFocused = false
    }

    private func highlightedName(_ name: String) -> AttributedString {
        var attrStr = AttributedString(name)
        let query = searchText.lowercased()
        if let range = attrStr.range(of: query, options: .caseInsensitive) {
            attrStr[range].font = .subheadline.bold()
            attrStr[range].foregroundColor = Theme.primaryColor
        }
        return attrStr
    }
}
