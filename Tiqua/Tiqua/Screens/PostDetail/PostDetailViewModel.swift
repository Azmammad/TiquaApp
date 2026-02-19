//
//  PostDetailViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 19.02.26.
//
import Foundation
import Combine
import CoreLocation
import FirebaseAuth

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var post: Post
    @Published var ownerProfileImageURL: String?
    @Published var comments: [Comment] = []
    @Published var feedback: [Feedback] = []
    @Published var isLiked: Bool = false
    @Published var likeCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var isDeleting: Bool = false
    @Published var isTogglingLike: Bool = false
    @Published var isSendingComment: Bool = false
    @Published var isSendingFeedback: Bool = false
    @Published var commentText: String = ""
    @Published var feedbackText: String = ""
    @Published var errorMessage: String?
    @Published var isNearLocation: Bool = false
    @Published var didDeletePost: Bool = false

    private let interactionService: PostInteractionServiceProtocol
    private let profileService: ProfileServiceProtocol
    private let postService: PostServiceProtocol
    private let locationManager: LocationManager
    private let maxFeedbackDistance: Double = 500

    var isOwner: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return post.ownerId == uid
    }

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    init(
        post: Post,
        interactionService: PostInteractionServiceProtocol,
        profileService: ProfileServiceProtocol,
        postService: PostServiceProtocol,
        locationManager: LocationManager
    ) {
        self.post = post
        self.interactionService = interactionService
        self.profileService = profileService
        self.postService = postService
        self.locationManager = locationManager
    }

    convenience init(post: Post) {
        self.init(
            post: post,
            interactionService: FirebasePostInteractionService(),
            profileService: ProfileService(),
            postService: FirebasePostService(),
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

    func loadLikeState() async {
        guard let uid = currentUserId else {
            isLiked = false
            likeCount = 0
            return
        }

        do {
            async let liked = interactionService.checkIfLiked(postId: post.id, userId: uid)
            async let count = interactionService.fetchLikeCount(postId: post.id)
            isLiked = try await liked
            likeCount = try await count
        } catch {
            isLiked = false
            likeCount = 0
        }
    }

    func toggleLike() async {
        guard let uid = currentUserId, !isTogglingLike else { return }

        isTogglingLike = true

        let previousLiked = isLiked
        let previousCount = likeCount

        isLiked = !previousLiked
        likeCount = previousLiked ? max(0, previousCount - 1) : previousCount + 1

        do {
            if previousLiked {
                try await interactionService.unlikePost(postId: post.id, userId: uid)
            } else {
                try await interactionService.likePost(postId: post.id, userId: uid)
            }
        } catch {
            isLiked = previousLiked
            likeCount = previousCount
            errorMessage = "Failed to update like. Please try again."
        }

        isTogglingLike = false
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

    func deletePost() async {
        isDeleting = true
        do {
            try await postService.deletePost(postId: post.id, imageURL: post.imageURL)
            didDeletePost = true
        } catch {
            errorMessage = "Failed to delete post. Please try again."
        }
        isDeleting = false
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
