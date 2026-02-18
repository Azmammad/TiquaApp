//
//  ProfileViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 17.02.26.
//
import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingPosts: Bool = false
    @Published var hasLoadedPosts: Bool = false
    @Published var errorMessage: String?

    private let profileService: ProfileServiceProtocol
    private let authService: AuthServiceProtocol
    private let postService: PostServiceProtocol

    init(
        profileService: ProfileServiceProtocol,
        authService: AuthServiceProtocol,
        postService: PostServiceProtocol
    ) {
        self.profileService = profileService
        self.authService = authService
        self.postService = postService
    }

    convenience init() {
        self.init(
            profileService: ProfileService(),
            authService: FirebaseAuthService(),
            postService: FirebasePostService()
        )
    }

    func loadUser() async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await profileService.fetchCurrentUser()
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

    func logout() async throws {
        try await authService.logout()
    }

    var postCount: Int {
        posts.count
    }

    var isPostsEmpty: Bool {
        hasLoadedPosts && !isLoadingPosts && posts.isEmpty
    }
}
