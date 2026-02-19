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
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
    }

    func fetchComments(postId: String) async throws -> [Comment] {
        let snapshot = try await db.collection("posts").document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments(source: .server)

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let postId = data["postId"] as? String,
                  let userId = data["userId"] as? String,
                  let username = data["username"] as? String,
                  let text = data["text"] as? String,
                  let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            else { return nil }

            return Comment(
                id: id,
                postId: postId,
                userId: userId,
                username: username,
                profileImageURL: data["profileImageURL"] as? String,
                text: text,
                createdAt: createdAt
            )
        }
    }

    func addComment(postId: String, text: String) async throws -> Comment {
        guard let user = try await authService.getCurrentUser() else {
            throw NSError(domain: "PostInteraction", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let ref = db.collection("posts").document(postId).collection("comments").document()
        let now = Date()

        let commentData: [String: Any] = [
            "id": ref.documentID,
            "postId": postId,
            "userId": user.id,
            "username": user.username,
            "profileImageURL": user.profileImageURL ?? "",
            "text": text,
            "createdAt": Timestamp(date: now)
        ]

        try await ref.setData(commentData)

        return Comment(
            id: ref.documentID,
            postId: postId,
            userId: user.id,
            username: user.username,
            profileImageURL: user.profileImageURL,
            text: text,
            createdAt: now
        )
    }

    func fetchFeedback(postId: String) async throws -> [Feedback] {
        let snapshot = try await db.collection("posts").document(postId)
            .collection("feedback")
            .order(by: "createdAt", descending: false)
            .getDocuments(source: .server)

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let postId = data["postId"] as? String,
                  let userId = data["userId"] as? String,
                  let username = data["username"] as? String,
                  let text = data["text"] as? String,
                  let isLocationVerified = data["isLocationVerified"] as? Bool,
                  let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            else { return nil }

            return Feedback(
                id: id,
                postId: postId,
                userId: userId,
                username: username,
                profileImageURL: data["profileImageURL"] as? String,
                text: text,
                isLocationVerified: isLocationVerified,
                createdAt: createdAt
            )
        }
    }

    func addFeedback(postId: String, text: String, latitude: Double, longitude: Double) async throws -> Feedback {
        guard let user = try await authService.getCurrentUser() else {
            throw NSError(domain: "PostInteraction", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let ref = db.collection("posts").document(postId).collection("feedback").document()
        let now = Date()

        let feedbackData: [String: Any] = [
            "id": ref.documentID,
            "postId": postId,
            "userId": user.id,
            "username": user.username,
            "profileImageURL": user.profileImageURL ?? "",
            "text": text,
            "isLocationVerified": true,
            "latitude": latitude,
            "longitude": longitude,
            "createdAt": Timestamp(date: now)
        ]

        try await ref.setData(feedbackData)

        return Feedback(
            id: ref.documentID,
            postId: postId,
            userId: user.id,
            username: user.username,
            profileImageURL: user.profileImageURL,
            text: text,
            isLocationVerified: true,
            createdAt: now
        )
    }

    func toggleLike(postId: String) async throws -> Bool {
        guard let user = try await authService.getCurrentUser() else {
            throw NSError(domain: "PostInteraction", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let likeRef = db.collection("posts").document(postId).collection("likes").document(user.id)
        let doc = try await likeRef.getDocument()

        if doc.exists {
            try await likeRef.delete()
            return false
        } else {
            try await likeRef.setData(["userId": user.id, "createdAt": Timestamp(date: Date())])
            return true
        }
    }

    func isLiked(postId: String) async throws -> Bool {
        guard let user = try await authService.getCurrentUser() else { return false }
        let doc = try await db.collection("posts").document(postId).collection("likes").document(user.id).getDocument()
        return doc.exists
    }

    func likeCount(postId: String) async throws -> Int {
        let snapshot = try await db.collection("posts").document(postId).collection("likes").getDocuments(source: .server)
        return snapshot.documents.count
    }
}