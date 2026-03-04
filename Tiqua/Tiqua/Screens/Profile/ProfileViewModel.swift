//
//  ProfileViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 17.02.26.
//
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var hasLoadedPosts: Bool = false
    @Published var errorMessage: String?
    @Published var followerCount: Int = 0
    @Published var savedCount: Int = 0

    private let profileService: ProfileServiceProtocol
    private let postService: PostServiceProtocol
    private let db = Firestore.firestore()

    init(
        profileService: ProfileServiceProtocol,
        postService: PostServiceProtocol
    ) {
        self.profileService = profileService
        self.postService = postService
    }

    convenience init() {
        self.init(
            profileService: ProfileService(),
            postService: FirebasePostService()
        )
    }

    func loadUser() async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await profileService.fetchCurrentUser()
            if let uid = user?.id {
                followerCount = try await profileService.fetchFollowerCount(userId: uid)
            }
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadUserPosts() async {
        guard let userId = user?.id else { return }

        isLoadingPosts = true
        posts = []

        do {
            posts = try await postService.fetchUserPosts(userId: userId, limit: 50, after: nil)
        } catch {
            posts = []
        }

        hasLoadedPosts = true
        isLoadingPosts = false
    }

    func loadSavedCount() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let snapshot = try await db.collection("users").document(uid)
                .collection("savedPosts").getDocuments()
            savedCount = snapshot.documents.count
        } catch {
            savedCount = 0
        }
    }

    var postCount: Int {
        posts.count
    }

    var isPostsEmpty: Bool {
        hasLoadedPosts && !isLoadingPosts && posts.isEmpty
    }
}
