//
//  EditProfileView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 17.02.26.
//
import SwiftUI
import PhotosUI
import Kingfisher

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()
    
    @State private var showErrorAlert = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentUserProfileImageURL: String?
    
    private let bioCharacterLimit = 150
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            profileImageView()
                                .overlay(
                                    Group {
                                        if viewModel.isUploadingImage {
                                            Circle()
                                                .fill(Color.black.opacity(0.5))
                                                .frame(width: 100, height: 100)
                                                .overlay(
                                                    ProgressView()
                                                        .tint(.white)
                                                )
                                        }
                                    }
                                )
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    )
                            }
                            .disabled(viewModel.isUploadingImage)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("Change Photo")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        .disabled(viewModel.isUploadingImage)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            TextField("Enter your full name", text: $viewModel.fullName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Bio")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(viewModel.bio.count)/\(bioCharacterLimit)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                if viewModel.bio.isEmpty {
                                    Text("Exploring the world one place at a time ✈️")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }
                                
                                TextEditor(text: $viewModel.bio)
                                    .textInputAutocapitalization(.sentences)
                                    .autocorrectionDisabled()
                                    .frame(minHeight: 100)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .onChange(of: viewModel.bio) { _, newValue in
                                        if newValue.count > bioCharacterLimit {
                                            viewModel.bio = String(newValue.prefix(bioCharacterLimit))
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    PrimaryButton(
                        title: "Save Changes",
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.fullName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty || viewModel.isUploadingImage
                    ) {
                        Task { await viewModel.saveProfile() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentColor)
                        .disabled(viewModel.isUploadingImage)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await viewModel.saveProfile() }
                    }
                    .foregroundColor(.accentColor)
                    .disabled(
                        viewModel.isLoading ||
                        viewModel.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        viewModel.isUploadingImage
                    )
                }
            }
            .task {
                await loadInitialData()
            }
            .onChange(of: selectedItem) { _, newValue in
                if let newValue {
                    Task { await viewModel.handlePhotoSelection(newValue) }
                }
            }
            .onChange(of: viewModel.isSaved) { _, newValue in
                if newValue { dismiss() }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    @ViewBuilder
    private func profileImageView() -> some View {
        if let selectedImage = viewModel.selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } else if let urlString = currentUserProfileImageURL,
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
    
    private func loadInitialData() async {
        await viewModel.loadCurrentUser()
        do {
            let user = try await ProfileService().fetchCurrentUser()
            currentUserProfileImageURL = user.profileImageURL
        } catch {
            print("Failed to load profile image URL: \(error)")
        }
    }
}

#Preview {
    EditProfileView()
}
