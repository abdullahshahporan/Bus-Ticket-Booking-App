//
//  District.swift
//  BusTicketBooking
//

import Foundation

struct District: Identifiable, Hashable {
    let id: String
    let name: String
    let bnName: String
}

struct DistrictAPIResponse: Codable {
    let success: Bool
    let data: [DistrictData]
}

struct DistrictData: Codable {
    let id: String
    let name: String
    let bnName: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bnName = "bn_name"
    }

    func toDistrict() -> District {
        District(id: id, name: name, bnName: bnName)
    }
}
