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

    func createPost(
        imageData: Data,
        caption: String?,
        locationName: String?,
        latitude: Double?,
        longitude: Double?
    ) async throws -> Post {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebasePostService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        let userDoc = try await db.collection("users").document(uid).getDocument()
        guard let username = userDoc.data()?["username"] as? String else {
            throw NSError(domain: "FirebasePostService", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Username not found."])
        }

        let postId = UUID().uuidString
        let storageRef = storage.reference().child("posts/\(uid)/\(postId).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()

        let now = Date()
        let data: [String: Any] = [
            "id": postId,
            "ownerId": uid,
            "username": username,
            "imageURL": downloadURL.absoluteString,
            "caption": caption as Any,
            "locationName": locationName as Any,
            "latitude": latitude as Any,
            "longitude": longitude as Any,
            "createdAt": Timestamp(date: now)
        ]

        try await db.collection("posts").document(postId).setData(data)

        if let locationName = locationName, !locationName.isEmpty {
            let cityName = extractCity(from: locationName)
            if !cityName.isEmpty {
                try await db.collection("users").document(uid).updateData([
                    "visitedCities": FieldValue.arrayUnion([cityName])
                ])
            }
        }

        return Post(
            id: postId,
            ownerId: uid,
            username: username,
            imageURL: downloadURL.absoluteString,
            caption: caption,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            createdAt: now
        )
    }

    func fetchUserPosts(userId: String, limit: Int, after: Date?) async throws -> [Post] {
        var query: Query = db.collection("posts")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let after = after {
            query = query.start(after: [Timestamp(date: after)])
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { decode(document: $0) }
    }

    func deletePost(postId: String, imageURL: String) async throws {
        try await db.collection("posts").document(postId).delete()

        if let url = URL(string: imageURL),
           url.host?.contains("firebasestorage") == true {
            let storageRef = storage.reference(forURL: imageURL)
            try await storageRef.delete()
        }
    }

    private func extractCity(from locationName: String) -> String {
        let components = locationName.components(separatedBy: ",")
        if components.count >= 2 {
            return components[components.count - 2].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return locationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decode(document: QueryDocumentSnapshot) -> Post? {
        let data = document.data()

        guard
            let id = data["id"] as? String,
            let ownerId = data["ownerId"] as? String,
            let username = data["username"] as? String,
            let imageURL = data["imageURL"] as? String,
            let timestamp = data["createdAt"] as? Timestamp
        else { return nil }

        return Post(
            id: id,
            ownerId: ownerId,
            username: username,
            imageURL: imageURL,
            caption: data["caption"] as? String,
            locationName: data["locationName"] as? String,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double,
            createdAt: timestamp.dateValue()
        )
    }
}
