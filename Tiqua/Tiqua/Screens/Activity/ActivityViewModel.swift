//
//  ActivityViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class ActivityViewModel: ObservableObject {
    @Published var activities: [ActivityItem] = []
    @Published var isLoading: Bool = false
    @Published var followStatuses: [String: Bool] = [:]
    @Published var togglingFollowIds: Set<String> = []
    @Published var cachedPosts: [String: Post] = [:]

    private let activityService = FirebaseActivityService()
    private let profileService: ProfileServiceProtocol = ProfileService()
    private var listener: ListenerRegistration?

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard listener == nil else { return }
        isLoading = true

        listener = activityService.listen(for: uid) { [weak self] items in
            Task { @MainActor in
                guard let self else { return }
                self.activities = items
                self.isLoading = false
                await self.loadFollowStatuses(for: items)
                await self.loadPostsForItems(items)
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func toggleFollow(for userId: String) async {
        guard let uid = Auth.auth().currentUser?.uid, uid != userId else { return }
        guard !togglingFollowIds.contains(userId) else { return }

        togglingFollowIds.insert(userId)
        let wasFollowing = followStatuses[userId] ?? false
        followStatuses[userId] = !wasFollowing

        do {
            if wasFollowing {
                try await profileService.unfollowUser(targetUserId: userId)
                await activityService.remove(from: userId, activityId: "follow_\(uid)")
            } else {
                try await profileService.followUser(targetUserId: userId)
                await activityService.send(
                    to: userId,
                    type: "follow",
                    postId: nil,
                    postImageURL: nil,
                    activityId: "follow_\(uid)"
                )
            }
        } catch {
            followStatuses[userId] = wasFollowing
        }

        togglingFollowIds.remove(userId)
    }

    func postForItem(_ item: ActivityItem) -> Post? {
        guard let postId = item.postId, !postId.isEmpty else { return nil }
        return cachedPosts[postId]
    }

    func activityText(for item: ActivityItem) -> String {
        switch item.type {
        case "like":
            return "\(item.fromUsername) liked your post"
        case "comment":
            return "\(item.fromUsername) commented on your post"
        case "feedback":
            return "\(item.fromUsername) left feedback on your post"
        case "follow":
            return "\(item.fromUsername) started following you"
        default:
            return "\(item.fromUsername) interacted with you"
        }
    }

    func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func iconName(for type: String) -> String {
        switch type {
        case "like": return "heart.fill"
        case "comment": return "bubble.left.fill"
        case "feedback": return "mappin.and.ellipse"
        case "follow": return "person.badge.plus"
        default: return "bell.fill"
        }
    }

    func iconColor(for type: String) -> Color {
        switch type {
        case "like": return Color.red
        case "comment": return Color.blue
        case "feedback": return Color.cyan
        case "follow": return Color.accentColor
        default: return Color.gray
        }
    }

    private func loadFollowStatuses(for items: [ActivityItem]) async {
        let followUserIds = items.filter { $0.type == "follow" }.map { $0.fromUserId }
        for userId in followUserIds {
            if followStatuses[userId] == nil {
                let isFollowing = try? await profileService.isFollowing(targetUserId: userId)
                followStatuses[userId] = isFollowing ?? false
            }
        }
    }

    private func loadPostsForItems(_ items: [ActivityItem]) async {
        let postIds = Set(items.compactMap { $0.postId }.filter { !$0.isEmpty })
        for postId in postIds {
            if cachedPosts[postId] == nil {
                if let post = await activityService.fetchPost(postId: postId) {
                    cachedPosts[postId] = post
                }
            }
        }
    }
}
