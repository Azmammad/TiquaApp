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
    func checkIfLiked(postId: String, userId: String) async throws -> Bool
    func likePost(postId: String, userId: String) async throws
    func unlikePost(postId: String, userId: String) async throws
    func fetchLikeCount(postId: String) async throws -> Int
}
