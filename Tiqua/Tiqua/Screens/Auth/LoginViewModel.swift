//
//  LoginViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//
import Foundation
import Combine
import FirebaseAuth

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var identifier: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var didLogin: Bool = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    convenience init() {
        self.init(authService: FirebaseAuthService())
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

    func sendPasswordReset(email: String) async throws -> String {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            throw NSError(
                domain: "ValidationError",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Please enter your email address."]
            )
        }

        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)

        guard emailPredicate.evaluate(with: trimmedEmail) else {
            throw NSError(
                domain: "ValidationError",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address."]
            )
        }

        try await authService.sendPasswordReset(email: trimmedEmail)
        return "Password reset link sent! Please check your email."
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
        if error.domain == AuthErrorDomain {
            let code = AuthErrorCode(rawValue: error.code)
            switch code {
            case .userNotFound:
                return "No account found with this email or username."
            case .wrongPassword, .invalidCredential:
                return "Incorrect password. Please try again."
            case .invalidEmail:
                return "Please enter a valid email address."
            case .userDisabled:
                return "This account has been disabled. Please contact support."
            case .tooManyRequests:
                return "Too many failed attempts. Please try again later."
            case .networkError:
                return "Network error. Please check your internet connection."
            default:
                if let desc = error.userInfo[NSLocalizedDescriptionKey] as? String, !desc.isEmpty {
                    return desc
                }
                return "Incorrect password. Please try again."
            }
        }

        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("user not found") || errorMessage.contains("username") {
            return "No account found with this username. Please check and try again."
        }

        if errorMessage.contains("email") && errorMessage.contains("not verified") {
            return "Please verify your email before logging in. Check your inbox for verification link."
        }

        if errorMessage.contains("network") || errorMessage.contains("internet") || errorMessage.contains("offline") {
            return "Network error. Please check your internet connection."
        }

        if errorMessage.contains("password") && (errorMessage.contains("wrong") || errorMessage.contains("invalid") || errorMessage.contains("incorrect")) {
            return "Incorrect password. Please try again."
        }

        if errorMessage.contains("permission") || errorMessage.contains("denied") {
            return "Unable to connect to the server. Please try again."
        }

        if let desc = error.userInfo[NSLocalizedDescriptionKey] as? String, !desc.isEmpty {
            return desc
        }

        return "Something went wrong. Please try again."
    }

    private func show(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
