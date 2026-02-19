//
//  PostDetailView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 19.02.26.
//
import SwiftUI
import Kingfisher

struct PostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostDetailViewModel

    init(post: Post) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                userInfoRow
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                postImage
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                actionRow
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                captionSection
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                if viewModel.post.latitude != nil && viewModel.post.longitude != nil {
                    verifiedBadge
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    feedbackSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }

                commentsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle(viewModel.post.username)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {} label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
        .task {
            await viewModel.loadAll()
        }
    }

    private var userInfoRow: some View {
        HStack(spacing: 12) {
            profileImage(url: viewModel.ownerProfileImageURL, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.post.username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                if let locationName = viewModel.post.locationName {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)

                        Text(locationName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        if viewModel.post.latitude != nil {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.accentColor)
                        }
                    }
                }

                Text(viewModel.timeAgoString(from: viewModel.post.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()
        }
    }

    private var postImage: some View {
        ZStack {
            Color.clear
                .aspectRatio(4.0 / 5.0, contentMode: .fit)

            KFImage(URL(string: viewModel.post.imageURL))
                .placeholder {
                    Color.gray.opacity(0.1)
                        .overlay(
                            ProgressView()
                                .tint(.gray)
                        )
                }
                .onFailure { _ in }
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(12)
    }

    private var actionRow: some View {
        HStack {
            HStack(spacing: 6) {
                Button {
                    Task { await viewModel.toggleLike() }
                } label: {
                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.isLiked ? .red : .primary)
                }

                if viewModel.likeCount > 0 {
                    Text("\(viewModel.likeCount)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            Button {} label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
            }
        }
    }

    @ViewBuilder
    private var captionSection: some View {
        if let caption = viewModel.post.caption, !caption.isEmpty {
            HStack(alignment: .top, spacing: 0) {
                (
                    Text(viewModel.post.username)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    + Text(" ")
                    + Text(caption)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                )

                Spacer(minLength: 0)
            }
        }
    }

    private var verifiedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.accentColor)

            Text("Location verified \u{2013} User was physically here when posting")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.accentColor.opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)

                Text("Local Feedback")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text("Only people currently at this location can leave feedback")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            if viewModel.isNearLocation {
                inputRow(
                    text: $viewModel.feedbackText,
                    placeholder: "Share your experience here...",
                    isSending: viewModel.isSendingFeedback
                ) {
                    Task { await viewModel.sendFeedback() }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("You must be at this location to leave feedback")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }

            ForEach(viewModel.feedback) { item in
                feedbackRow(item)
            }
        }
        .padding(16)
        .background(Color("feedbackColor"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
        )
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Comments")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            inputRow(
                text: $viewModel.commentText,
                placeholder: "Add a comment...",
                isSending: viewModel.isSendingComment
            ) {
                Task { await viewModel.sendComment() }
            }

            ForEach(viewModel.comments) { comment in
                commentRow(comment)
            }

            if viewModel.comments.isEmpty && !viewModel.isLoading {
                Text("No comments yet")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }

    private func inputRow(text: Binding<String>, placeholder: String, isSending: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(22)

            Button(action: action) {
                if isSending {
                    ProgressView()
                        .tint(.gray)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(
                            text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .gray.opacity(0.4)
                            : .accentColor
                        )
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
    }

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            profileImage(url: comment.profileImageURL, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(comment.username)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)

                Text(viewModel.timeAgoString(from: comment.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6).opacity(0.7))
            .cornerRadius(12)
        }
    }

    private func feedbackRow(_ item: Feedback) -> some View {
        HStack(alignment: .top, spacing: 10) {
            profileImage(url: item.profileImageURL, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(item.username)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    if item.isLocationVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.accentColor)
                    }
                }

                Text(item.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)

                Text(viewModel.timeAgoString(from: item.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func profileImage(url: String?, size: CGFloat) -> some View {
        if let urlString = url, !urlString.isEmpty, let imageURL = URL(string: urlString) {
            KFImage(imageURL)
                .placeholder {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
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
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundColor(.gray)
                )
        }
    }
}
