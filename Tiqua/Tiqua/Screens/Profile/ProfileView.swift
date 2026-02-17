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

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.user == nil {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let errorMessage = viewModel.errorMessage {
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
                            Task { await viewModel.loadUser() }
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

                            HStack(spacing: 0) {
                                VStack(spacing: 4) {
                                    Text("42")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Posts")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)

                                Divider()
                                    .frame(height: 40)

                                VStack(spacing: 4) {
                                    Text("18")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Saved")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)

                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(0..<9, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .aspectRatio(1, contentMode: .fit)
                                        .cornerRadius(4)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.system(size: 30))
                                                .foregroundColor(.gray.opacity(0.5))
                                        )
                                }
                            }
                            .padding(.horizontal, 2)

                            Button {
                                Task {
                                    do {
                                        try await viewModel.logout()
                                        preferences.isLoggedIn = false
                                        router.route = .login
                                    } catch {
                                        viewModel.errorMessage = "Failed to log out. Please try again."
                                    }
                                }
                            } label: {
                                Text("Log Out")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 40)
                        }
                    }
                    .refreshable {
                        await viewModel.loadUser()
                    }
                }
            }
            .navigationTitle(viewModel.user?.username ?? "Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await viewModel.loadUser()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .onChange(of: showEditProfile) { _, newValue in
                if !newValue {
                    Task { await viewModel.loadUser() }
                }
            }
        }
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
