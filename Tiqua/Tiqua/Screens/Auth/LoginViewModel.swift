//
//  LoginViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//
import Foundation
import Combine

final class LoginViewModel: ObservableObject {
    @Published var identifier: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var didLogin: Bool = false

    private let authService: AuthService

    init(authService: AuthService = FirebaseAuthService()) {
        self.authService = authService
    }

    func login() async {
        guard validateInputs() else { return }
        isLoading = true

        do {
            _ = try await authService.login(
                identifier: identifier,
                password: password
            )
            didLogin = true
        } catch let error as AuthError {
            show(error.localizedDescription)
        } catch {
            show(parseFriendlyError(error))
        }

        isLoading = false
    }

    private func validateInputs() -> Bool {
        if identifier.trimmingCharacters(in: .whitespaces).isEmpty {
            show("Email or username is required.")
            return false
        }

        if password.isEmpty {
            show("Password is required.")
            return false
        }

        return true
    }

    private func parseFriendlyError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription
        
        if errorMessage.contains("network") || errorMessage.contains("internet") {
            return "Network error. Please check your internet connection."
        }
        
        if errorMessage.contains("user") && errorMessage.contains("not found") {
            return "No account found with this email or username."
        }
        
        if errorMessage.contains("password") && (errorMessage.contains("wrong") || errorMessage.contains("invalid")) {
            return "Incorrect password. Please try again."
        }
        
        if errorMessage.contains("too-many-requests") {
            return "Too many failed attempts. Please try again later."
        }
        
        return "Login failed. Please check your credentials and try again."
    }

    private func show(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
