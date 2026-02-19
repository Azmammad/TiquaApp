//
//  Comment.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 19.02.26.
//


import Foundation

struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    let username: String
    let profileImageURL: String?
    let text: String
    let createdAt: Date
}