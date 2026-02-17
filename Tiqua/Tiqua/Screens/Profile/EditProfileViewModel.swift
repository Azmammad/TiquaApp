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

            guard let compressedData = compressImage(uiImage) else {
                throw NSError(
                    domain: "EditProfileViewModel",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]
                )
            }

            let url = try await profileService.uploadProfileImage(compressedData)
            profileImageURL = url
        } catch {
            errorMessage = "Failed to upload image: \(error.localizedDescription)"
            selectedImage = nil
        }

        isUploadingImage = false
    }

    private func compressImage(_ image: UIImage) -> Data? {
        let maxSize: CGFloat = 1024
        let size = image.size

        var newSize: CGSize
        if size.width > size.height {
            let ratio = maxSize / size.width
            newSize = CGSize(width: maxSize, height: size.height * ratio)
        } else {
            let ratio = maxSize / size.height
            newSize = CGSize(width: size.width * ratio, height: maxSize)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage.jpegData(compressionQuality: 0.7)
    }
}
