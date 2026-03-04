//
//  ActivityItem.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//
import Foundation

struct ActivityItem: Codable, Identifiable {
    let id: String
    let type: String
    let fromUserId: String
    let fromUsername: String
    let fromProfileImageURL: String?
    let postId: String?
    let postImageURL: String?
    let postOwnerId: String?
    let createdAt: Date
}
