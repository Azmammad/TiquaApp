//
//  Post.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 18.02.26.
//
import Foundation

struct Post: Codable, Identifiable {
    let id: String
    let ownerId: String
    let username: String
    let imageURL: String
    var caption: String?
    let locationName: String?
    let countryName: String?
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date

    var countryDisplayName: String? {
        if let countryName = countryName, !countryName.isEmpty {
            return countryName
        }
        guard let locationName = locationName, !locationName.isEmpty else { return nil }
        let components = locationName.components(separatedBy: ",")
        let country = components.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return country.isEmpty ? nil : country
    }

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case username
        case imageURL
        case caption
        case locationName
        case countryName
        case latitude
        case longitude
        case createdAt
    }
}
