//
//  SavedPostCardView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 21.02.26.
//
import SwiftUI
import Kingfisher

struct SavedPostCardView: View {
    let post: Post
    let isDeleteMode: Bool
    let onDelete: () -> Void

    @State private var wiggleAngle: Double = 0

    private let cardColors: [Color] = [
        Color("lightBlue"),
        Color("lightOrange"),
        Color("lightPurple"),
        Color("lightTeal")
    ]

    private var cardColor: Color {
        let index = abs(post.id.hashValue) % cardColors.count
        return cardColors[index]
    }

    private var primaryText: String? {
        if let caption = post.caption, !caption.isEmpty {
            return caption
        }
        return post.countryDisplayName
    }

    private var secondaryText: String? {
        guard let caption = post.caption, !caption.isEmpty else {
            return nil
        }
        return post.countryDisplayName
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    KFImage(URL(string: post.imageURL))
                        .placeholder {
                            Color.gray.opacity(0.2)
                                .overlay(ProgressView().tint(.gray))
                        }
                        .onFailure { _ in }
                        .fade(duration: 0.25)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 2 / 3)
                        .clipped()

                    VStack(alignment: .leading, spacing: 3) {
                        if let primary = primaryText {
                            Text(primary)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        if let secondary = secondaryText {
                            Text(secondary)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height * 1 / 3, alignment: .leading)
                    .padding(.horizontal, 10)
                    .background(cardColor)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .rotationEffect(.degrees(wiggleAngle))

            if isDeleteMode {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white, .red)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .offset(x: -8, y: -8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 200)
        .onChange(of: isDeleteMode) { _, newValue in
            if newValue {
                startWiggle()
            } else {
                stopWiggle()
            }
        }
    }

    private func startWiggle() {
        wiggleAngle = 0
        withAnimation(
            .easeInOut(duration: 0.13)
            .repeatForever(autoreverses: true)
        ) {
            wiggleAngle = 1.8
        }
    }

    private func stopWiggle() {
        withAnimation(.easeInOut(duration: 0.1)) {
            wiggleAngle = 0
        }
    }
}
