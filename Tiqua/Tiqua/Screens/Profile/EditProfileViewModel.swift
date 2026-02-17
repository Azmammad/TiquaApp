//
//  EditProfileViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 17.02.26.
//
import Foundation
import UIKit
import Combine
import PhotosUI
import SwiftUI

@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var bio: String = ""
    @Published var profileImageURL: String?
    @Published var selectedImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var isUploadingImage: Bool = false
    @Published var errorMessage: String?
    @Published var isSaved: Bool = false

    private let profileService: ProfileServiceProtocol

    init(profileService: ProfileServiceProtocol) {
        self.profileService = profileService
    }

    convenience init() {
        self.init(profileService: ProfileService())
    }

    func loadCurrentUser() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await profileService.fetchCurrentUser()
            fullName = user.fullName ?? ""
            bio = user.bio ?? ""
            profileImageURL = user.profileImageURL
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func saveProfile() async {
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Full name cannot be empty"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await profileService.updateProfile(
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isSaved = true
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func handlePhotoSelection(_ item: PhotosPickerItem) async {
        isUploadingImage = true
        errorMessage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw NSError(
                    domain: "EditProfileViewModel",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"]
                )
            }

            guard let uiImage = UIImage(data: data) else {
                throw NSError(
                    domain: "EditProfileViewModel",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"]
                )
            }

            selectedImage = uiImage
            let url = try await profileService.uploadProfileImage(uiImage)
            profileImageURL = url
        } catch {
            errorMessage = "Failed to upload image: \(error.localizedDescription)"
            selectedImage = nil
        }

        isUploadingImage = false
    }
}
