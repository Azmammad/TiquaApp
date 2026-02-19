//
//  PostInteractionServiceProtocol.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 19.02.26.
//


import Foundation

protocol PostInteractionServiceProtocol {
    func fetchComments(postId: String) async throws -> [Comment]
    func addComment(postId: String, text: String) async throws -> Comment
    func fetchFeedback(postId: String) async throws -> [Feedback]
    func addFeedback(postId: String, text: String, latitude: Double, longitude: Double) async throws -> Feedback
    func toggleLike(postId: String) async throws -> Bool
    func isLiked(postId: String) async throws -> Bool
    func likeCount(postId: String) async throws -> Int
}