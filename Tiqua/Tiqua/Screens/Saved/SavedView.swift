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
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
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
                if viewModel.isDeleteMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.exitDeleteMode()
                            }
                        } label: {
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentColor, lineWidth: 1.5)
                                )
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .task {
                await viewModel.loadSavedPosts()
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isDeleteMode)
        }
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.savedPosts) { post in
                    Group {
                        if viewModel.isDeleteMode {
                            SavedPostCardView(
                                post: post,
                                isDeleteMode: viewModel.isDeleteMode
                            ) {
                                Task { await viewModel.removeSavedPost(postId: post.id) }
                            }
                        } else {
                            NavigationLink(destination: PostDetailView(post: post)) {
                                SavedPostCardView(
                                    post: post,
                                    isDeleteMode: viewModel.isDeleteMode
                                ) {
                                    Task { await viewModel.removeSavedPost(postId: post.id) }
                                }
                            }
                            .buttonStyle(.plain)
                            .onLongPressGesture(minimumDuration: 0.4) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.enterDeleteMode()
                                }
                            }
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
