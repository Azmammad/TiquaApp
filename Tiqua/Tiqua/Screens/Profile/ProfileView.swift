//
//  ProfileView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 13.02.26.
//
import SwiftUI
import Kingfisher

struct ProfileView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var preferences: AppPreferences

    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showSavedView = false
    @State private var showFollowersList = false
    @Binding var switchToTab: MainTabView.Tab

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.user == nil {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let errorMessage = viewModel.errorMessage, viewModel.user == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)

                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button("Retry") {
                            Task {
                                await viewModel.loadUser()
                                await viewModel.loadUserPosts()
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                    }
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

                            Button {
                                showEditProfile = true
                            } label: {
                                Text("Edit Profile")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 24)

                            statsSection

                            postsSection
                        }
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await viewModel.loadUser()
                        await viewModel.loadUserPosts()
                        await viewModel.loadSavedCount()
                    }
                }
            }
            .navigationTitle(viewModel.user?.username ?? "Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await viewModel.loadUser()
                await viewModel.loadUserPosts()
                await viewModel.loadSavedCount()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .onChange(of: showEditProfile) { _, newValue in
                if !newValue {
                    Task {
                        await viewModel.loadUser()
                        await viewModel.loadUserPosts()
                    }
                }
            }
            .navigationDestination(isPresented: $showFollowersList) {
                FollowersListView(userId: viewModel.user?.id ?? "")
            }
            .sheet(isPresented: $showSavedView) {
                SavedView()
            }
            .onChange(of: showSavedView) { _, newValue in
                if !newValue {
                    Task {
                        await viewModel.loadSavedCount()
                    }
                }
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(viewModel.postCount)")
                    .font(.system(size: 20, weight: .bold))
                Text("Posts")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            Button {
                showFollowersList = true
            } label: {
                VStack(spacing: 4) {
                    Text("\(viewModel.followerCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Followers")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            Button {
                showSavedView = true
            } label: {
                VStack(spacing: 4) {
                    Text("\(viewModel.savedCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Saved")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var postsSection: some View {
        if viewModel.isLoadingPosts && !viewModel.hasLoadedPosts {
            ProgressView()
                .padding(.vertical, 40)
        } else if viewModel.isPostsEmpty {
            emptyPostsView
        } else if !viewModel.posts.isEmpty {
            postsGridView
        }
    }

    private var emptyPostsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundColor(.accentColor.opacity(0.4))

            VStack(spacing: 8) {
                Text("No posts yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("Start sharing your world with Tiqua")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                switchToTab = .create
            } label: {
                Text("Create your first post")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.accentColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 48)
            .padding(.top, 4)
        }
        .padding(.vertical, 40)
    }

    private var postsGridView: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.posts) { post in
                NavigationLink(destination: PostDetailView(post: post)) {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            KFImage(URL(string: post.imageURL))
                                .placeholder {
                                    Color.gray.opacity(0.15)
                                        .overlay(
                                            ProgressView()
                                                .tint(.gray)
                                        )
                                }
                                .onFailure { _ in }
                                .fade(duration: 0.25)
                                .resizable()
                                .scaledToFill()
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .id(post.id)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func profileImageView(url: String?) -> some View {
        if let urlString = url,
           let imageURL = URL(string: urlString) {
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
