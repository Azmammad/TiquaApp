//
//  FirebaseActivityService.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseActivityService {
    private let db = Firestore.firestore()

    func send(to targetUserId: String, type: String, postId: String?, postImageURL: String?, activityId: String) async {
        guard let uid = Auth.auth().currentUser?.uid, uid != targetUserId else { return }

        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Unknown"
            let profileImageURL = userDoc.data()?["profileImageURL"] as? String

            var data: [String: Any] = [
                "id": activityId,
                "type": type,
                "fromUserId": uid,
                "fromUsername": username,
                "postOwnerId": targetUserId,
                "createdAt": Timestamp(date: Date())
            ]

            if let profileImageURL = profileImageURL {
                data["fromProfileImageURL"] = profileImageURL
            }
            if let postId = postId, !postId.isEmpty {
                data["postId"] = postId
            }
            if let postImageURL = postImageURL, !postImageURL.isEmpty {
                data["postImageURL"] = postImageURL
            }

            try await db.collection("users").document(targetUserId)
                .collection("activities").document(activityId).setData(data)
        } catch {
            print("FirebaseActivityService.send error: \(error.localizedDescription)")
        }
    }

    func remove(from targetUserId: String, activityId: String) async {
        do {
            try await db.collection("users").document(targetUserId)
                .collection("activities").document(activityId).delete()
        } catch {
            print("FirebaseActivityService.remove error: \(error.localizedDescription)")
        }
    }

    func fetchPost(postId: String) async -> Post? {
        guard !postId.isEmpty else { return nil }
        do {
            let doc = try await db.collection("posts").document(postId).getDocument()
            guard let data = doc.data(),
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
                countryName: data["countryName"] as? String,
                latitude: data["latitude"] as? Double,
                longitude: data["longitude"] as? Double,
                createdAt: timestamp.dateValue()
            )
        } catch {
            return nil
        }
    }

    func listen(for userId: String, onChange: @escaping ([ActivityItem]) -> Void) -> ListenerRegistration {
        db.collection("users").document(userId).collection("activities")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("FirebaseActivityService.listen error: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot else {
                    onChange([])
                    return
                }
                let items = snapshot.documents.compactMap { doc -> ActivityItem? in
                    let data = doc.data()
                    guard
                        let id = data["id"] as? String,
                        let type = data["type"] as? String,
                        let fromUserId = data["fromUserId"] as? String,
                        let fromUsername = data["fromUsername"] as? String,
                        let timestamp = data["createdAt"] as? Timestamp
                    else { return nil }

                    return ActivityItem(
                        id: id,
                        type: type,
                        fromUserId: fromUserId,
                        fromUsername: fromUsername,
                        fromProfileImageURL: data["fromProfileImageURL"] as? String,
                        postId: data["postId"] as? String,
                        postImageURL: data["postImageURL"] as? String,
                        postOwnerId: data["postOwnerId"] as? String,
                        createdAt: timestamp.dateValue()
                    )
                }
                onChange(items)
            }
    }
}
