//
//  UserProfileView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//
import SwiftUI
import Kingfisher
import FirebaseAuth

struct UserProfileView: View {
    let userId: String

    @StateObject private var viewModel: UserProfileViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(userId: userId))
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.user == nil {
                ProgressView().scaleEffect(1.4)
            } else if let user = viewModel.user {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            profileImageView(url: user.profileImageURL)

                            Text(user.fullName ?? user.username)
                                .font(.system(size: 20, weight: .bold))

                            if let bio = user.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .padding(.top, 20)

                        if !viewModel.isOwnProfile {
                            Button {
                                Task { await viewModel.toggleFollow() }
                            } label: {
                                Text(viewModel.isFollowing ? "Following" : "Follow")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(viewModel.isFollowing ? .primary : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(viewModel.isFollowing ? Color(.systemGray6) : Color.accentColor)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 24)
                            .disabled(viewModel.isToggling)
                        }

                        statsSection

                        postsGrid
                    }
                    .padding(.bottom, 40)
                }
            } else if viewModel.errorMessage != nil {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Failed to load profile")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await viewModel.loadAll() }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.accentColor)
                }
            }
        }
        .navigationTitle(viewModel.user?.username ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAll()
        }
    }

    private var statsSection: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(viewModel.posts.count)")
                    .font(.system(size: 20, weight: .bold))
                Text("Posts")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(viewModel.followerCount)")
                    .font(.system(size: 20, weight: .bold))
                Text("Followers")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var postsGrid: some View {
        if viewModel.posts.isEmpty && !viewModel.isLoading {
            Text("No posts yet")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.posts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                KFImage(URL(string: post.imageURL))
                                    .placeholder {
                                        Color.gray.opacity(0.15)
                                            .overlay(ProgressView().tint(.gray))
                                    }
                                    .onFailure { _ in }
                                    .fade(duration: 0.25)
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func profileImageView(url: String?) -> some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            KFImage(imageURL)
                .placeholder {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                )
        }
    }
}
