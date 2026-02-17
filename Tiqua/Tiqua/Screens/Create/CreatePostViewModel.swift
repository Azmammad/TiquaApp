//
//  CreatePostViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 18.02.26.
//


import Foundation
import Combine

@MainActor
final class CreatePostViewModel: ObservableObject {
    @Published var caption: String = ""
    @Published var selectedImageData: Data?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var didCreateSuccessfully: Bool = false

    private let postService: PostServiceProtocol

    init(postService: PostServiceProtocol) {
        self.postService = postService
    }

    convenience init() {
        self.init(postService: FirebasePostService())
    }

    func createPost(locationName: String?, latitude: Double?, longitude: Double?) async {
        guard let imageData = selectedImageData else {
            errorMessage = "Please select an image."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedLocation = locationName?.trimmingCharacters(in: .whitespacesAndNewlines)

            _ = try await postService.createPost(
                imageData: imageData,
                caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                locationName: (trimmedLocation?.isEmpty ?? true) ? nil : trimmedLocation,
                latitude: latitude,
                longitude: longitude
            )
            didCreateSuccessfully = true
        } catch {
            errorMessage = "Failed to create post: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func reset() {
        caption = ""
        selectedImageData = nil
        isLoading = false
        errorMessage = nil
        didCreateSuccessfully = false
    }
}
