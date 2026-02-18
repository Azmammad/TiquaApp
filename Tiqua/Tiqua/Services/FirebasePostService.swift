//
//  FirebasePostService.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 18.02.26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class FirebasePostService: PostServiceProtocol {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
    }

    func createPost(imageData: Data, caption: String?, locationName: String?, latitude: Double?, longitude: Double?) async throws -> Post {
        guard let currentUser = try await authService.getCurrentUser() else {
            throw NSError(
                domain: "FirebasePostService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"]
            )
        }

        let postId = db.collection("posts").document().documentID
        let storageRef = storage.reference().child("post_images/\(currentUser.id)/\(postId).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        let imageURL = downloadURL.absoluteString

        let now = Date()

        var postData: [String: Any] = [
            "id": postId,
            "ownerId": currentUser.id,
            "username": currentUser.username,
            "imageURL": imageURL,
            "createdAt": Timestamp(date: now)
        ]

        if let caption = caption?.trimmingCharacters(in: .whitespacesAndNewlines), !caption.isEmpty {
            postData["caption"] = caption
        }

        if let locationName = locationName?.trimmingCharacters(in: .whitespacesAndNewlines), !locationName.isEmpty {
            postData["locationName"] = locationName
        }

        if let latitude = latitude {
            postData["latitude"] = latitude
        }

        if let longitude = longitude {
            postData["longitude"] = longitude
        }

        try await db.collection("posts").document(postId).setData(postData)

        return Post(
            id: postId,
            ownerId: currentUser.id,
            username: currentUser.username,
            imageURL: imageURL,
            caption: caption,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            createdAt: now
        )
    }

    func fetchPosts(limit: Int, after: Date?) async throws -> [Post] {
        var query: Query = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let after = after {
            query = query.whereField("createdAt", isLessThan: Timestamp(date: after))
        }

        let snapshot = try await query.getDocuments(source: .server)
        return snapshot.documents.compactMap { parsePost(from: $0) }
    }

    func fetchUserPosts(userId: String, limit: Int, after: Date?) async throws -> [Post] {
        var query: Query = db.collection("posts")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let after = after {
            query = query.whereField("createdAt", isLessThan: Timestamp(date: after))
        }

        let snapshot = try await query.getDocuments(source: .server)
        return snapshot.documents.compactMap { parsePost(from: $0) }
    }

    func deletePost(_ postId: String) async throws {
        guard let currentUser = try await authService.getCurrentUser() else {
            throw NSError(
                domain: "FirebasePostService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"]
            )
        }

        let postDoc = try await db.collection("posts").document(postId).getDocument()

        guard let data = postDoc.data(),
              let ownerId = data["ownerId"] as? String,
              ownerId == currentUser.id else {
            throw NSError(
                domain: "FirebasePostService",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "You can only delete your own posts"]
            )
        }

        let storageRef = storage.reference().child("post_images/\(currentUser.id)/\(postId).jpg")

        do {
            try await storageRef.delete()
        } catch {
        }

        try await db.collection("posts").document(postId).delete()
    }

    private func parsePost(from document: DocumentSnapshot) -> Post? {
        guard let data = document.data(),
              let id = data["id"] as? String,
              let ownerId = data["ownerId"] as? String,
              let username = data["username"] as? String,
              let imageURL = data["imageURL"] as? String,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }

        return Post(
            id: id,
            ownerId: ownerId,
            username: username,
            imageURL: imageURL,
            caption: data["caption"] as? String,
            locationName: data["locationName"] as? String,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double,
            createdAt: createdAt
        )
    }
}
