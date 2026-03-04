//
//  DiscoverPostCard.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 25.02.26.
//
import SwiftUI
import Kingfisher

struct DiscoverPostCard: View {
    let post: Post
    let width: CGFloat
    let height: CGFloat

    @State private var isLiked: Bool = false
    @State private var showHeart: Bool = false
    @State private var heartScale: CGFloat = 0.4
    @State private var heartOpacity: Double = 0

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
                triggerLike()
            }
        )
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
                Button {} label: {
                    Image(systemName: "bookmark")
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
                    triggerLike()
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

    private func triggerLike() {
        isLiked.toggle()
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
