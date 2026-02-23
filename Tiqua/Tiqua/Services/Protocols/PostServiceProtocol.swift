//
//  PostServiceProtocol.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 18.02.26.
//
import Foundation

protocol PostServiceProtocol {
    func createPost(
        imageData: Data,
        caption: String?,
        locationName: String?,
        latitude: Double?,
        longitude: Double?,
        countryName: String?
    ) async throws -> Post

    func fetchUserPosts(userId: String, limit: Int, after: Date?) async throws -> [Post]

    func deletePost(postId: String, imageURL: String) async throws
}
