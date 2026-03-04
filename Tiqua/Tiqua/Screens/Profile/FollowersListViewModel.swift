//
//  FollowersListViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class FollowersListViewModel: ObservableObject {
    @Published var followers: [User] = []
    @Published var followStatuses: [String: Bool] = [:]
    @Published var togglingIds: Set<String> = []
    @Published var isLoading: Bool = false

    let userId: String
    private let profileService: ProfileServiceProtocol
    private let db = Firestore.firestore()

    init(userId: String, profileService: ProfileServiceProtocol = ProfileService()) {
        self.userId = userId
        self.profileService = profileService
    }

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func loadFollowers() async {
        isLoading = true

        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("followers")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            let followerIds = snapshot.documents.compactMap { $0.data()["userId"] as? String }

            var users: [User] = []
            for id in followerIds {
                if let user = try? await profileService.fetchUser(userId: id) {
                    users.append(user)
                }
            }
            followers = users

            for user in followers {
                if user.id != currentUserId {
                    let isFollowing = try? await profileService.isFollowing(targetUserId: user.id)
                    followStatuses[user.id] = isFollowing ?? false
                }
            }
        } catch {
            followers = []
        }

        isLoading = false
    }

    func toggleFollow(for user: User) async {
        guard let uid = currentUserId, uid != user.id, !togglingIds.contains(user.id) else { return }

        togglingIds.insert(user.id)
        let wasFollowing = followStatuses[user.id] ?? false
        followStatuses[user.id] = !wasFollowing

        do {
            if wasFollowing {
                try await profileService.unfollowUser(targetUserId: user.id)
                let activityService = FirebaseActivityService()
                await activityService.remove(from: user.id, activityId: "follow_\(uid)")
            } else {
                try await profileService.followUser(targetUserId: user.id)
                let activityService = FirebaseActivityService()
                await activityService.send(
                    to: user.id,
                    type: "follow",
                    postId: nil,
                    postImageURL: nil,
                    activityId: "follow_\(uid)"
                )
            }
        } catch {
            followStatuses[user.id] = wasFollowing
        }

        togglingIds.remove(user.id)
    }

    func isOwnProfile(_ user: User) -> Bool {
        user.id == currentUserId
    }
}