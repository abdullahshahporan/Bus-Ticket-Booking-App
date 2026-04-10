//
//  DistrictService.swift
//  BusTicketBooking
//

import Foundation

@MainActor
class DistrictService: ObservableObject {
    static let shared = DistrictService()

    @Published var districts: [District] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let primaryURL = "https://bdapis.vercel.app/geo/v2.0/districts"
    private let fallbackURL = "https://bdapi.vercel.app/api/v.1/district"

    func fetchDistricts() async {
        guard districts.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        if let fetched = try? await fetchFromURL(primaryURL) {
            districts = fetched.sorted { $0.name < $1.name }
            isLoading = false
            return
        }

        if let fetched = try? await fetchFromURL(fallbackURL) {
            districts = fetched.sorted { $0.name < $1.name }
            isLoading = false
            return
        }

        errorMessage = "Failed to load districts. Check your internet connection."
        isLoading = false
    }

    private func fetchFromURL(_ urlString: String) async throws -> [District] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(DistrictAPIResponse.self, from: data)
        return decoded.data.map { $0.toDistrict() }
    }
}
