//
//  SavedViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 21.02.26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var savedPosts: [Post] = []
    @Published var isDeleteMode: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let postService: PostServiceProtocol
    private let interactionService: PostInteractionServiceProtocol
    private let db = Firestore.firestore()

    init(
        postService: PostServiceProtocol,
        interactionService: PostInteractionServiceProtocol
    ) {
        self.postService = postService
        self.interactionService = interactionService
    }

    convenience init() {
        self.init(
            postService: FirebasePostService(),
            interactionService: FirebasePostInteractionService()
        )
    }

    func loadSavedPosts() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true

        do {
            let snapshot = try await db
                .collection("users")
                .document(uid)
                .collection("savedPosts")
                .order(by: "savedAt", descending: true)
                .getDocuments()

            let postIds = snapshot.documents.compactMap { $0.data()["postId"] as? String }

            var posts: [Post] = []
            for postId in postIds {
                if let post = try? await fetchPost(postId: postId) {
                    posts.append(post)
                } else {
                    try? await db
                        .collection("users")
                        .document(uid)
                        .collection("savedPosts")
                        .document(postId)
                        .delete()
                }
            }

            savedPosts = posts
        } catch {
            errorMessage = "Failed to load saved posts."
        }

        isLoading = false
    }

    func enterDeleteMode() {
        isDeleteMode = true
    }

    func exitDeleteMode() {
        isDeleteMode = false
    }

    func removeSavedPost(postId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            try await interactionService.unsavePost(postId: postId, userId: uid)
            savedPosts.removeAll { $0.id == postId }
        } catch {
            errorMessage = "Failed to remove saved post."
        }
    }

    private func fetchPost(postId: String) async throws -> Post? {
        let doc = try await db.collection("posts").document(postId).getDocument()

        guard doc.exists,
              let data = doc.data(),
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
    }
}
