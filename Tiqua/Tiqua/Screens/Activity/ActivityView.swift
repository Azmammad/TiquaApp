//
//  ActivityView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//
import SwiftUI
import Kingfisher

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.activities.isEmpty {
                    ProgressView()
                        .scaleEffect(1.4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.activities.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.activities) { item in
                                activityRow(item)

                                if item.id != viewModel.activities.last?.id {
                                    Divider()
                                        .padding(.leading, 72)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.startListening()
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        let badgeColor = viewModel.iconColor(for: item.type)
        let badgeIcon = viewModel.iconName(for: item.type)
        let cachedPost = viewModel.postForItem(item)

        return HStack(spacing: 12) {
            NavigationLink(destination: UserProfileView(userId: item.fromUserId)) {
                ZStack(alignment: .bottomTrailing) {
                    profileImage(url: item.fromProfileImageURL, size: 44)

                    Image(systemName: badgeIcon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(badgeColor)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)

            NavigationLink(destination: UserProfileView(userId: item.fromUserId)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.activityText(for: item))
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(viewModel.timeAgo(from: item.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if item.type == "follow" {
                followButton(for: item)
            } else if let post = cachedPost {
                NavigationLink(destination: PostDetailView(post: post)) {
                    postThumbnail(url: item.postImageURL)
                }
                .buttonStyle(.plain)
            } else {
                postThumbnail(url: item.postImageURL)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func postThumbnail(url: String?) -> some View {
        if let imageURL = url, !imageURL.isEmpty {
            KFImage(URL(string: imageURL))
                .placeholder {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                }
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func followButton(for item: ActivityItem) -> some View {
        let isFollowing = viewModel.followStatuses[item.fromUserId] ?? false
        let isToggling = viewModel.togglingFollowIds.contains(item.fromUserId)

        Button {
            Task { await viewModel.toggleFollow(for: item.fromUserId) }
        } label: {
            Text(isFollowing ? "Following" : "Follow")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isFollowing ? .primary : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(isFollowing ? Color(.systemGray6) : Color.accentColor)
                .cornerRadius(8)
        }
        .disabled(isToggling)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundColor(.accentColor.opacity(0.4))

            VStack(spacing: 8) {
                Text("No activity yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("When people interact with your posts, you'll see it here")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
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
