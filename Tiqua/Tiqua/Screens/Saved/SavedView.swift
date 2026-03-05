//
//  SavedView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 14.02.26.
//
import SwiftUI

struct SavedView: View {
    @StateObject private var viewModel = SavedViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 0)
    ]

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.savedPosts.isEmpty {
                ProgressView()
                    .scaleEffect(1.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.savedPosts.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                scrollContent
            }
        }
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.savedPosts.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if viewModel.isDeleteMode {
                                viewModel.exitDeleteMode()
                            } else {
                                viewModel.enterDeleteMode()
                            }
                        }
                    } label: {
                        Text(viewModel.isDeleteMode ? "Done" : "Edit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .task {
            await viewModel.loadSavedPosts()
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isDeleteMode)
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.savedPosts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        SavedPostCardView(
                            post: post,
                            isDeleteMode: viewModel.isDeleteMode
                        ) {
                            Task { await viewModel.removeSavedPost(postId: post.id) }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isDeleteMode)
                    .onLongPressGesture(minimumDuration: 0.4) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.enterDeleteMode()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 56))
                .foregroundColor(.accentColor.opacity(0.4))

            VStack(spacing: 8) {
                Text("No saved posts yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("Save posts from your travels to view them here")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}
