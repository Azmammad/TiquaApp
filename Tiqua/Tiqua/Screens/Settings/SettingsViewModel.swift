//
//  SettingsViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 18.02.26.
//


import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isLoggingOut: Bool = false
    @Published var errorMessage: String?
    @Published var didLogout: Bool = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    convenience init() {
        self.init(authService: FirebaseAuthService())
    }

    func logout() async {
        isLoggingOut = true
        errorMessage = nil

        do {
            try await authService.logout()
            didLogout = true
        } catch {
            errorMessage = "Failed to log out. Please try again."
        }

        isLoggingOut = false
    }
}
