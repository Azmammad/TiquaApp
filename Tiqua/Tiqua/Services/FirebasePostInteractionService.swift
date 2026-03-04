//
//  FirebasePostInteractionService.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 19.02.26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebasePostInteractionService: PostInteractionServiceProtocol {

    private let db = Firestore.firestore()

    func fetchComments(postId: String) async throws -> [Comment] {
        let snapshot = try await db
            .collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { decodeComment($0) }
    }

    func addComment(postId: String, text: String) async throws -> Comment {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebasePostInteractionService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        let userDoc = try await db.collection("users").document(uid).getDocument()
        let username = userDoc.data()?["username"] as? String ?? "Unknown"
        let profileImageURL = userDoc.data()?["profileImageURL"] as? String

        let commentId = UUID().uuidString
        let now = Date()

        let data: [String: Any] = [
            "id": commentId,
            "postId": postId,
            "userId": uid,
            "username": username,
            "profileImageURL": profileImageURL as Any,
            "text": text,
            "createdAt": Timestamp(date: now)
        ]

        try await db
            .collection("posts")
            .document(postId)
            .collection("comments")
            .document(commentId)
            .setData(data)

        return Comment(
            id: commentId,
            postId: postId,
            userId: uid,
            username: username,
            profileImageURL: profileImageURL,
            text: text,
            createdAt: now
        )
    }

    func deleteComment(postId: String, commentId: String) async throws {
        try await db
            .collection("posts")
            .document(postId)
            .collection("comments")
            .document(commentId)
            .delete()
    }

    func fetchFeedback(postId: String) async throws -> [Feedback] {
        let snapshot = try await db
            .collection("posts")
            .document(postId)
            .collection("feedback")
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { decodeFeedback($0) }
    }

    func addFeedback(postId: String, text: String, latitude: Double, longitude: Double) async throws -> Feedback {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebasePostInteractionService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        let userDoc = try await db.collection("users").document(uid).getDocument()
        let username = userDoc.data()?["username"] as? String ?? "Unknown"
        let profileImageURL = userDoc.data()?["profileImageURL"] as? String

        let feedbackId = UUID().uuidString
        let now = Date()

        let data: [String: Any] = [
            "id": feedbackId,
            "postId": postId,
            "userId": uid,
            "username": username,
            "profileImageURL": profileImageURL as Any,
            "text": text,
            "isLocationVerified": true,
            "createdAt": Timestamp(date: now)
        ]

        try await db
            .collection("posts")
            .document(postId)
            .collection("feedback")
            .document(feedbackId)
            .setData(data)

        return Feedback(
            id: feedbackId,
            postId: postId,
            userId: uid,
            username: username,
            profileImageURL: profileImageURL,
            text: text,
            isLocationVerified: true,
            createdAt: now
        )
    }

    func deleteFeedback(postId: String, feedbackId: String) async throws {
        try await db
            .collection("posts")
            .document(postId)
            .collection("feedback")
            .document(feedbackId)
            .delete()
    }

    func checkIfLiked(postId: String, userId: String) async throws -> Bool {
        let doc = try await db
            .collection("posts")
            .document(postId)
            .collection("likes")
            .document(userId)
            .getDocument()

        return doc.exists
    }

    func likePost(postId: String, userId: String) async throws {
        let data: [String: Any] = [
            "userId": userId,
            "createdAt": Timestamp(date: Date())
        ]

        try await db
            .collection("posts")
            .document(postId)
            .collection("likes")
            .document(userId)
            .setData(data)
    }

    func unlikePost(postId: String, userId: String) async throws {
        try await db
            .collection("posts")
            .document(postId)
            .collection("likes")
            .document(userId)
            .delete()
    }

    func fetchLikeCount(postId: String) async throws -> Int {
        let snapshot = try await db
            .collection("posts")
            .document(postId)
            .collection("likes")
            .getDocuments()

        return snapshot.documents.count
    }

    func savePost(postId: String, userId: String) async throws {
        let data: [String: Any] = [
            "postId": postId,
            "savedAt": Timestamp(date: Date())
        ]

        try await db
            .collection("users")
            .document(userId)
            .collection("savedPosts")
            .document(postId)
            .setData(data)
    }

    func unsavePost(postId: String, userId: String) async throws {
        try await db
            .collection("users")
            .document(userId)
            .collection("savedPosts")
            .document(postId)
            .delete()
    }

    func isPostSaved(postId: String, userId: String) async throws -> Bool {
        let doc = try await db
            .collection("users")
            .document(userId)
            .collection("savedPosts")
            .document(postId)
            .getDocument()

        return doc.exists
    }

    func updateCaption(postId: String, caption: String) async throws {
        try await db
            .collection("posts")
            .document(postId)
            .updateData(["caption": caption])
    }

    private func decodeComment(_ document: QueryDocumentSnapshot) -> Comment? {
        let data = document.data()

        guard
            let id = data["id"] as? String,
            let postId = data["postId"] as? String,
            let userId = data["userId"] as? String,
            let username = data["username"] as? String,
            let text = data["text"] as? String,
            let timestamp = data["createdAt"] as? Timestamp
        else { return nil }

        return Comment(
            id: id,
            postId: postId,
            userId: userId,
            username: username,
            profileImageURL: data["profileImageURL"] as? String,
            text: text,
            createdAt: timestamp.dateValue()
        )
    }

    private func decodeFeedback(_ document: QueryDocumentSnapshot) -> Feedback? {
        let data = document.data()

        guard
            let id = data["id"] as? String,
            let postId = data["postId"] as? String,
            let userId = data["userId"] as? String,
            let username = data["username"] as? String,
            let text = data["text"] as? String,
            let isLocationVerified = data["isLocationVerified"] as? Bool,
            let timestamp = data["createdAt"] as? Timestamp
        else { return nil }

        return Feedback(
            id: id,
            postId: postId,
            userId: userId,
            username: username,
            profileImageURL: data["profileImageURL"] as? String,
            text: text,
            isLocationVerified: isLocationVerified,
            createdAt: timestamp.dateValue()
        )
    }
}
