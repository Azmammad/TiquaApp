//
//  DiscoverCarouselSection.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 25.02.26.
//
import SwiftUI

struct DiscoverCarouselSection: View {
    let posts: [Post]
    @Binding var currentPostId: String?

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * 0.80
            let cardHeight = geo.size.height

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(posts) { post in
                        DiscoverPostCard(post: post, width: cardWidth, height: cardHeight)
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.96)
                                    .opacity(phase.isIdentity ? 1 : 0.78)
                            }
                            .id(post.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPostId)
            .frame(width: geo.size.width, height: cardHeight)
        }
    }
}
