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
}

