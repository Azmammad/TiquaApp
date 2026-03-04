//
//  UserProfileViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//
import Foundation
import FirebaseAuth
import Combine

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isFollowing: Bool = false
    @Published var isToggling: Bool = false
    @Published var followerCount: Int = 0
    @Published var errorMessage: String?

    let userId: String
    private let profileService: ProfileServiceProtocol
    private let postService: PostServiceProtocol

    var isOwnProfile: Bool {
        Auth.auth().currentUser?.uid == userId
    }

    init(
        userId: String,
        profileService: ProfileServiceProtocol = ProfileService(),
        postService: PostServiceProtocol = FirebasePostService()
    ) {
        self.userId = userId
        self.profileService = profileService
        self.postService = postService
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await profileService.fetchUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return
        }

        do {
            posts = try await postService.fetchUserPosts(userId: userId, limit: 50, after: nil)
        } catch {
            posts = []
        }

        do {
            followerCount = try await profileService.fetchFollowerCount(userId: userId)
        } catch {
            followerCount = 0
        }

        if !isOwnProfile {
            do {
                isFollowing = try await profileService.isFollowing(targetUserId: userId)
            } catch {
                isFollowing = false
            }
        }

        isLoading = false
    }

    func toggleFollow() async {
        guard !isToggling else { return }
        isToggling = true

        let wasFollowing = isFollowing
        isFollowing = !wasFollowing
        followerCount += wasFollowing ? -1 : 1

        do {
            if wasFollowing {
                try await profileService.unfollowUser(targetUserId: userId)
            } else {
                try await profileService.followUser(targetUserId: userId)
            }
        } catch {
            isFollowing = wasFollowing
            followerCount += wasFollowing ? 1 : -1
        }

        isToggling = false
    }
}
