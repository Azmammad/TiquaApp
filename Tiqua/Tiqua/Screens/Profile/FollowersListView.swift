//
//  FollowersListView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//


import SwiftUI
import Kingfisher

struct FollowersListView: View {
    let userId: String
    @StateObject private var viewModel: FollowersListViewModel

    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: FollowersListViewModel(userId: userId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.followers.isEmpty {
                ProgressView()
                    .scaleEffect(1.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.followers.isEmpty && !viewModel.isLoading {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 48))
                        .foregroundColor(Color(.systemGray3))
                    Text("No followers yet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.followers) { user in
                            NavigationLink(destination: UserProfileView(userId: user.id)) {
                                followerRow(user)
                            }
                            .buttonStyle(.plain)

                            if user.id != viewModel.followers.last?.id {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Followers")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFollowers()
        }
    }

    private func followerRow(_ user: User) -> some View {
        HStack(spacing: 12) {
            profileImage(url: user.profileImageURL, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(user.username)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let fullName = user.fullName, !fullName.isEmpty {
                    Text(fullName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !viewModel.isOwnProfile(user) {
                Button {
                    Task { await viewModel.toggleFollow(for: user) }
                } label: {
                    let isFollowing = viewModel.followStatuses[user.id] ?? false
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isFollowing ? .primary : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(isFollowing ? Color(.systemGray6) : Color.accentColor)
                        .cornerRadius(8)
                }
                .disabled(viewModel.togglingIds.contains(user.id))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func profileImage(url: String?, size: CGFloat) -> some View {
        if let urlString = url, !urlString.isEmpty, let imageURL = URL(string: urlString) {
            KFImage(imageURL)
                .placeholder {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: size * 0.45))
                                .foregroundColor(.gray)
                        )
                }
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundColor(.gray)
                )
        }
    }
}