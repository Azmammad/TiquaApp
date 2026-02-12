//
//  RegisterViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//
import Foundation
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isCheckingUsername: Bool = false
    @Published var isUsernameAvailable: Bool? = nil

    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var didRegisterSuccessfully: Bool = false

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService = FirebaseAuthService()) {
        self.authService = authService
        observeUsernameChanges()
    }

    private func observeUsernameChanges() {
        $username
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                Task {
                    await self.checkUsernameAvailability(value)
                }
            }
            .store(in: &cancellables)
    }

    private func checkUsernameAvailability(_ value: String) async {
        guard !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            isUsernameAvailable = nil
            return
        }

        guard value.count >= 3 else {
            isUsernameAvailable = nil
            return
        }

        isCheckingUsername = true

        do {
            let available = try await authService.checkUsernameAvailability(value)
            isUsernameAvailable = available
        } catch {
            isUsernameAvailable = nil
            print("Username availability check error: \(error.localizedDescription)")
        }

        isCheckingUsername = false
    }

    func register() async {
        guard validateInputs() else { return }
        isLoading = true

        do {
            _ = try await authService.register(
                username: username,
                email: email,
                password: password
            )
            didRegisterSuccessfully = true
            show("Account created! Please check your email to verify your account.", isSuccess: true)
        } catch let error as AuthError {
            show(error.localizedDescription)
        } catch {
            show(parseFriendlyError(error))
        }

        isLoading = false
    }

    private func validateInputs() -> Bool {
        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            show("Username is required.")
            return false
        }

        if username.count < 3 {
            show("Username must be at least 3 characters long.")
            return false
        }

        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            show("Email is required.")
            return false
        }

        if !isValidEmail(email) {
            show("Please enter a valid email address.")
            return false
        }

        if password.isEmpty {
            show("Password is required.")
            return false
        }

        if !AuthValidation.isValidPassword(password) {
            show("Password must be at least 8 characters with upper and lower case letters and a number.")
            return false
        }

        if isUsernameAvailable == false {
            show("This username is not available.")
            return false
        }

        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func parseFriendlyError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription
        
        if errorMessage.contains("network") || errorMessage.contains("internet") {
            return "Network error. Please check your internet connection."
        }
        
        if errorMessage.contains("email") && errorMessage.contains("already") {
            return "This email is already registered. Please login or use a different email."
        }
        
        if errorMessage.contains("password") && errorMessage.contains("weak") {
            return "Password is too weak. Please use a stronger password."
        }
        
        return "An error occurred. Please try again."
    }

    private func show(_ message: String, isSuccess: Bool = false) {
        alertMessage = message
        showAlert = true
    }
}
