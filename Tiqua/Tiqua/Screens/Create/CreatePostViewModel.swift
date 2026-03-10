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

    @Published var locationName: String?
    @Published var locationSubtitle: String?
    @Published var countryName: String?
    @Published var latitude: Double?
    @Published var longitude: Double?

    let locationManager: LocationManager
    private let postService: PostServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(postService: PostServiceProtocol, locationManager: LocationManager) {
        self.postService = postService
        self.locationManager = locationManager
        observeLocation()
    }

    convenience init() {
        self.init(
            postService: FirebasePostService(),
            locationManager: LocationManager()
        )
    }

    private func observeLocation() {
        locationManager.$latitude
            .receive(on: RunLoop.main)
            .assign(to: &$latitude)

        locationManager.$longitude
            .receive(on: RunLoop.main)
            .assign(to: &$longitude)

        locationManager.$locationName
            .receive(on: RunLoop.main)
            .assign(to: &$locationName)

        locationManager.$locationSubtitle
            .receive(on: RunLoop.main)
            .assign(to: &$locationSubtitle)

        locationManager.$countryName
            .receive(on: RunLoop.main)
            .assign(to: &$countryName)
    }

    func requestLocation() {
        locationManager.requestLocation()
    }

    func createPost() async {
        guard let imageData = selectedImageData else {
            errorMessage = "Please select an image."
            return
        }

        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCaption.isEmpty else {
            errorMessage = "Please add a caption before publishing."
            return
        }

        guard latitude != nil, longitude != nil else {
            errorMessage = "Location is required to create a post."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let trimmedLocation = locationName?.trimmingCharacters(in: .whitespacesAndNewlines)

            _ = try await postService.createPost(
                imageData: imageData,
                caption: trimmedCaption,
                locationName: (trimmedLocation?.isEmpty ?? true) ? nil : trimmedLocation,
                latitude: latitude,
                longitude: longitude,
                countryName: countryName
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

    var isLocationAvailable: Bool {
        latitude != nil && longitude != nil && locationName != nil
    }

    var postButtonDisabled: Bool {
        selectedImageData == nil || latitude == nil || longitude == nil || isLoading
    }
}
