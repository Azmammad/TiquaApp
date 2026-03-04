//
//  DiscoverPostCard.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 25.02.26.
//
import SwiftUI
import Kingfisher
import FirebaseAuth

struct DiscoverPostCard: View {
    let post: Post
    let width: CGFloat
    let height: CGFloat

    @State private var isLiked: Bool = false
    @State private var isSaved: Bool = false
    @State private var showHeart: Bool = false
    @State private var heartScale: CGFloat = 0.4
    @State private var heartOpacity: Double = 0

    private let interactionService: PostInteractionServiceProtocol = FirebasePostInteractionService()
    private let activityService = FirebaseActivityService()

    var body: some View {
        NavigationLink(destination: PostDetailView(post: post)) {
            ZStack {
                imageLayer

                gradientLayer

                overlayContent

                if showHeart {
                    heartBurst
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                handleDoubleTapLike()
            }
        )
        .task {
            await loadStates()
        }
    }

    private var imageLayer: some View {
        KFImage(URL(string: post.imageURL))
            .placeholder {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(ProgressView().tint(.gray))
            }
            .onFailure { _ in }
            .fade(duration: 0.25)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
    }

    private var gradientLayer: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0),
                Color.black.opacity(0.15),
                Color.black.opacity(0.72)
            ],
            startPoint: .center,
            endPoint: .bottom
        )
        .frame(width: width, height: height)
    }

    private var overlayContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    handleSaveTap()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
            }

            Spacer()

            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.countryDisplayName ?? post.locationName ?? "")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("@\(post.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    handleLikeTap()
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isLiked ? .red : .white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .frame(width: width, height: height)
    }

    private var heartBurst: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 72))
            .foregroundColor(.white.opacity(0.9))
            .scaleEffect(heartScale)
            .opacity(heartOpacity)
    }

    private func loadStates() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if let liked = try? await interactionService.checkIfLiked(postId: post.id, userId: uid) {
            isLiked = liked
        }
        if let saved = try? await interactionService.isPostSaved(postId: post.id, userId: uid) {
            isSaved = saved
        }
    }

    private func handleDoubleTapLike() {
        if !isLiked {
            isLiked = true
            persistLike(shouldLike: true)
        }
        showHeartAnimation()
    }

    private func handleLikeTap() {
        isLiked.toggle()
        persistLike(shouldLike: isLiked)
        if isLiked {
            showHeartAnimation()
        }
    }

    private func handleSaveTap() {
        isSaved.toggle()
        let shouldSave = isSaved
        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            do {
                if shouldSave {
                    try await interactionService.savePost(postId: post.id, userId: uid)
                } else {
                    try await interactionService.unsavePost(postId: post.id, userId: uid)
                }
            } catch {
                await MainActor.run { isSaved = !shouldSave }
            }
        }
    }

    private func persistLike(shouldLike: Bool) {
        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            do {
                if shouldLike {
                    try await interactionService.likePost(postId: post.id, userId: uid)
                    await activityService.send(
                        to: post.ownerId,
                        type: "like",
                        postId: post.id,
                        postImageURL: post.imageURL,
                        activityId: "like_\(uid)_\(post.id)"
                    )
                } else {
                    try await interactionService.unlikePost(postId: post.id, userId: uid)
                    await activityService.remove(
                        from: post.ownerId,
                        activityId: "like_\(uid)_\(post.id)"
                    )
                }
            } catch {
                await MainActor.run { isLiked = !shouldLike }
            }
        }
    }

    private func showHeartAnimation() {
        showHeart = true
        heartScale = 0.4
        heartOpacity = 1

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            heartScale = 1.2
        }

        withAnimation(.easeOut(duration: 0.25).delay(0.35)) {
            heartOpacity = 0
            heartScale = 1.5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            showHeart = false
            heartScale = 0.4
        }
    }
}
