//
//  PostDetailViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 19.02.26.
//


import Foundation
import Combine
import CoreLocation

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var post: Post
    @Published var ownerProfileImageURL: String?
    @Published var comments: [Comment] = []
    @Published var feedback: [Feedback] = []
    @Published var isLiked: Bool = false
    @Published var likeCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var isSendingComment: Bool = false
    @Published var isSendingFeedback: Bool = false
    @Published var commentText: String = ""
    @Published var feedbackText: String = ""
    @Published var errorMessage: String?
    @Published var isNearLocation: Bool = false

    private let interactionService: PostInteractionServiceProtocol
    private let profileService: ProfileServiceProtocol
    private let locationManager: LocationManager
    private let maxFeedbackDistance: Double = 500

    init(
        post: Post,
        interactionService: PostInteractionServiceProtocol,
        profileService: ProfileServiceProtocol,
        locationManager: LocationManager
    ) {
        self.post = post
        self.interactionService = interactionService
        self.profileService = profileService
        self.locationManager = locationManager
    }

    convenience init(post: Post) {
        self.init(
            post: post,
            interactionService: FirebasePostInteractionService(),
            profileService: ProfileService(),
            locationManager: LocationManager()
        )
    }

    func loadAll() async {
        isLoading = true
        async let commentsTask: () = loadComments()
        async let feedbackTask: () = loadFeedback()
        async let likeTask: () = loadLikeState()
        async let ownerTask: () = loadOwnerProfile()
        _ = await (commentsTask, feedbackTask, likeTask, ownerTask)
        checkLocationProximity()
        isLoading = false
    }

    func loadComments() async {
        do {
            comments = try await interactionService.fetchComments(postId: post.id)
        } catch {
            comments = []
        }
    }

    func loadFeedback() async {
        do {
            feedback = try await interactionService.fetchFeedback(postId: post.id)
        } catch {
            feedback = []
        }
    }

    func sendComment() async {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSendingComment = true
        do {
            let comment = try await interactionService.addComment(postId: post.id, text: trimmed)
            comments.append(comment)
            commentText = ""
        } catch {
            errorMessage = "Failed to send comment"
        }
        isSendingComment = false
    }

    func sendFeedback() async {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let lat = locationManager.latitude, let lng = locationManager.longitude else {
            errorMessage = "Location not available"
            return
        }

        isSendingFeedback = true
        do {
            let fb = try await interactionService.addFeedback(postId: post.id, text: trimmed, latitude: lat, longitude: lng)
            feedback.append(fb)
            feedbackText = ""
        } catch {
            errorMessage = "Failed to send feedback"
        }
        isSendingFeedback = false
    }

    func toggleLike() async {
        do {
            let newState = try await interactionService.toggleLike(postId: post.id)
            isLiked = newState
            likeCount += newState ? 1 : -1
        } catch {
            errorMessage = "Failed to update like"
        }
    }

    private func loadLikeState() async {
        do {
            async let liked = interactionService.isLiked(postId: post.id)
            async let count = interactionService.likeCount(postId: post.id)
            isLiked = try await liked
            likeCount = try await count
        } catch {}
    }

    private func loadOwnerProfile() async {
        do {
            let user = try await profileService.fetchCurrentUser()
            if user.id == post.ownerId {
                ownerProfileImageURL = user.profileImageURL
            }
        } catch {}
    }

    func checkLocationProximity() {
        locationManager.requestLocation()
        guard let userLat = locationManager.latitude,
              let userLng = locationManager.longitude,
              let postLat = post.latitude,
              let postLng = post.longitude else {
            isNearLocation = false
            return
        }

        let userLocation = CLLocation(latitude: userLat, longitude: userLng)
        let postLocation = CLLocation(latitude: postLat, longitude: postLng)
        let distance = userLocation.distance(from: postLocation)
        isNearLocation = distance <= maxFeedbackDistance
    }

    func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}