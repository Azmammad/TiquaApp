//
//  LoginViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//
import Foundation
import Combine
import FirebaseAuth

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
                identifier: identifier.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            didLogin = true
        } catch let error as AuthError {
            show(error.localizedDescription)
        } catch let error as NSError {
            show(parseFriendlyError(error))
        } catch {
            show("An unexpected error occurred. Please try again.")
        }

        isLoading = false
    }

    private func validateInputs() -> Bool {
        let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedIdentifier.isEmpty {
            show("Email or username is required.")
            return false
        }

        if password.isEmpty {
            show("Password is required.")
            return false
        }

        return true
    }

    private func parseFriendlyError(_ error: NSError) -> String {
        let errorMessage = error.localizedDescription.lowercased()
        
        if error.domain == AuthErrorDomain {
            switch error.code {
            case AuthErrorCode.userNotFound.rawValue:
                return "No account found with this email or username."
            case AuthErrorCode.wrongPassword.rawValue:
                return "Incorrect password. Please try again."
            case AuthErrorCode.invalidEmail.rawValue:
                return "Please enter a valid email address."
            case AuthErrorCode.userDisabled.rawValue:
                return "This account has been disabled. Please contact support."
            case AuthErrorCode.tooManyRequests.rawValue:
                return "Too many failed attempts. Please try again later."
            case AuthErrorCode.networkError.rawValue:
                return "Network error. Please check your internet connection."
            default:
                break
            }
        }
        
        if errorMessage.contains("user not found") {
            return "Username or email not found. Please check and try again."
        }
        
        if errorMessage.contains("email") && errorMessage.contains("not verified") {
            return "Please verify your email before logging in. Check your inbox for verification link."
        }
        
        if errorMessage.contains("network") || errorMessage.contains("internet") {
            return "Network error. Please check your internet connection."
        }
        
        if errorMessage.contains("password") && (errorMessage.contains("wrong") || errorMessage.contains("invalid") || errorMessage.contains("incorrect")) {
            return "Incorrect password. Please try again."
        }
        
        return "Login failed. Please check your credentials and try again."
    }

    private func show(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
