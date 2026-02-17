//
//  ProfileViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 17.02.26.
//


import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let profileService: ProfileServiceProtocol
    private let authService: AuthServiceProtocol

    init(
        profileService: ProfileServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        self.profileService = profileService
        self.authService = authService
    }

    convenience init() {
        self.init(
            profileService: ProfileService(),
            authService: FirebaseAuthService()
        )
    }

    func loadUser() async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await profileService.fetchCurrentUser()
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func logout() async throws {
        try await authService.logout()
    }
}