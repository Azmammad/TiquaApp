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
import FirebaseFirestore

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var post: Post
    @Published var ownerProfileImageURL: String?
    @Published var comments: [Comment] = []
    @Published var feedbacks: [Feedback] = []
    @Published var isLiked: Bool = false
    @Published var likeCount: Int = 0
    @Published var isSaved: Bool = false
    @Published var isSaveLoading: Bool = false
    @Published var isLoading: Bool = false
    @Published var isFeedbackLoading: Bool = false
    @Published var isDeleting: Bool = false
    @Published var isTogglingLike: Bool = false
    @Published var isSendingComment: Bool = false
    @Published var isSendingFeedback: Bool = false
    @Published var commentText: String = ""
    @Published var feedbackText: String = ""
    @Published var errorMessage: String?
    @Published var isNearLocation: Bool = false
    @Published var didDeletePost: Bool = false
    @Published var canLeaveFeedback: Bool = false
    @Published var feedbackVerificationType: String?
    @Published var isEditingCaption: Bool = false
    @Published var editedCaption: String = ""

    private let interactionService: PostInteractionServiceProtocol
    private let profileService: ProfileServiceProtocol
    private let postService: PostServiceProtocol
    private let locationManager: LocationManager
    private let activityService = FirebaseActivityService()
    private let db = Firestore.firestore()
    private let maxFeedbackDistance: Double = 300

    var isOwner: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return post.ownerId == uid
    }

    var currentUserId: String? {
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
        async let savedTask: () = loadSavedState()
        async let ownerTask: () = loadOwnerProfile()
        async let permissionTask: () = checkFeedbackPermission()
        _ = await (commentsTask, feedbackTask, likeTask, savedTask, ownerTask, permissionTask)
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
        isFeedbackLoading = true
        do {
            feedbacks = try await interactionService.fetchFeedback(postId: post.id)
        } catch {
            feedbacks = []
        }
        isFeedbackLoading = false
    }

    func checkFeedbackPermission() async {
        canLeaveFeedback = false
        feedbackVerificationType = nil

        guard let uid = currentUserId else { return }

        if uid == post.ownerId {
            canLeaveFeedback = false
            feedbackVerificationType = nil
            return
        }

        guard post.latitude != nil, post.longitude != nil else { return }

        locationManager.requestLocation()

        if let userLat = locationManager.latitude,
           let userLng = locationManager.longitude,
           let postLat = post.latitude,
           let postLng = post.longitude {
            let userLocation = CLLocation(latitude: userLat, longitude: userLng)
            let postLocation = CLLocation(latitude: postLat, longitude: postLng)
            let distance = userLocation.distance(from: postLocation)

            if distance <= maxFeedbackDistance {
                canLeaveFeedback = true
                feedbackVerificationType = "gps"
                isNearLocation = true
                return
            }
        }

        guard let postCity = extractCity(from: post.locationName) else {
            canLeaveFeedback = false
            return
        }

        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let visitedCities = userDoc.data()?["visitedCities"] as? [String] ?? []

            if visitedCities.contains(postCity) {
                canLeaveFeedback = true
                feedbackVerificationType = "historical"
            } else {
                canLeaveFeedback = false
            }
        } catch {
            canLeaveFeedback = false
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

    func loadSavedState() async {
        guard let uid = currentUserId else {
            isSaved = false
            return
        }

        do {
            isSaved = try await interactionService.isPostSaved(postId: post.id, userId: uid)
        } catch {
            isSaved = false
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
                await activityService.remove(
                    from: post.ownerId,
                    activityId: "like_\(uid)_\(post.id)"
                )
            } else {
                try await interactionService.likePost(postId: post.id, userId: uid)
                await activityService.send(
                    to: post.ownerId,
                    type: "like",
                    postId: post.id,
                    postImageURL: post.imageURL,
                    activityId: "like_\(uid)_\(post.id)"
                )
            }
        } catch {
            isLiked = previousLiked
            likeCount = previousCount
            errorMessage = "Failed to update like. Please try again."
        }

        isTogglingLike = false
    }

    func toggleSave() async {
        guard let uid = currentUserId, !isSaveLoading else { return }

        isSaveLoading = true

        let previousSaved = isSaved
        isSaved = !previousSaved

        do {
            if previousSaved {
                try await interactionService.unsavePost(postId: post.id, userId: uid)
            } else {
                try await interactionService.savePost(postId: post.id, userId: uid)
            }
        } catch {
            isSaved = previousSaved
            errorMessage = "Failed to update saved state. Please try again."
        }

        isSaveLoading = false
    }

    func sendComment() async {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSendingComment = true
        do {
            let comment = try await interactionService.addComment(postId: post.id, text: trimmed)
            comments.append(comment)
            commentText = ""

            await activityService.send(
                to: post.ownerId,
                type: "comment",
                postId: post.id,
                postImageURL: post.imageURL,
                activityId: "comment_\(comment.id)"
            )
        } catch {
            errorMessage = "Failed to send comment"
        }
        isSendingComment = false
    }

    func deleteComment(_ comment: Comment) async {
        do {
            try await interactionService.deleteComment(postId: post.id, commentId: comment.id)
            comments.removeAll { $0.id == comment.id }
            await activityService.remove(
                from: post.ownerId,
                activityId: "comment_\(comment.id)"
            )
        } catch {
            errorMessage = "Failed to delete comment"
        }
    }

    func addFeedback(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canLeaveFeedback else { return }
        guard let lat = locationManager.latitude, let lng = locationManager.longitude else {
            errorMessage = "Location not available"
            return
        }

        isSendingFeedback = true
        do {
            var fb = try await interactionService.addFeedback(
                postId: post.id,
                text: trimmed,
                latitude: lat,
                longitude: lng
            )
            fb.verificationType = feedbackVerificationType
            feedbacks.append(fb)
            feedbackText = ""

            await activityService.send(
                to: post.ownerId,
                type: "feedback",
                postId: post.id,
                postImageURL: post.imageURL,
                activityId: "feedback_\(fb.id)"
            )
        } catch {
            errorMessage = "Failed to send feedback"
        }
        isSendingFeedback = false
    }

    func deleteFeedback(_ feedback: Feedback) async {
        do {
            try await interactionService.deleteFeedback(postId: post.id, feedbackId: feedback.id)
            feedbacks.removeAll { $0.id == feedback.id }
            await activityService.remove(
                from: post.ownerId,
                activityId: "feedback_\(feedback.id)"
            )
        } catch {
            errorMessage = "Failed to delete feedback"
        }
    }

    func startEditingCaption() {
        editedCaption = post.caption ?? ""
        isEditingCaption = true
    }

    func saveCaption() async {
        let trimmed = editedCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await interactionService.updateCaption(postId: post.id, caption: trimmed)
            post.caption = trimmed
            isEditingCaption = false
        } catch {
            errorMessage = "Failed to update caption"
        }
    }

    func cancelEditingCaption() {
        isEditingCaption = false
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

    func canDeleteComment(_ comment: Comment) -> Bool {
        guard let uid = currentUserId else { return false }
        return comment.userId == uid || isOwner
    }

    func canDeleteFeedback(_ feedback: Feedback) -> Bool {
        guard let uid = currentUserId else { return false }
        return feedback.userId == uid
    }

    func onLocationTapped() {
        guard post.latitude != nil, post.longitude != nil else { return }
    }

    private func loadOwnerProfile() async {
        do {
            let ownerDoc = try await db.collection("users").document(post.ownerId).getDocument()
            ownerProfileImageURL = ownerDoc.data()?["profileImageURL"] as? String
        } catch {}
    }

    private func extractCity(from locationName: String?) -> String? {
        guard let locationName = locationName, !locationName.isEmpty else { return nil }
        let components = locationName.components(separatedBy: ",")
        if components.count >= 2 {
            return components[components.count - 2].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return locationName.trimmingCharacters(in: .whitespacesAndNewlines)
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
