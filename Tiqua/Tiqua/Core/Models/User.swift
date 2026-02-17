//
//  User.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let createdAt: Date
    let isEmailVerified: Bool
    
    var fullName: String?
    var bio: String?
    var profileImageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt
        case isEmailVerified
        case fullName
        case bio
        case profileImageURL
    }
}
