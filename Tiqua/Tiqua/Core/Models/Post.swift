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
    let caption: String?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case username
        case imageURL
        case caption
        case locationName
        case latitude
        case longitude
        case createdAt
    }
}