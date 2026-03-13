//
//  LoginView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import SwiftUI

struct LoginView: View {

    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var preferences: AppPreferences

    @StateObject private var viewModel = LoginViewModel()
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Tiqua")
                            .font(.system(size: 40, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.appPrimary)

                        Text("Welcome back to authentic travel")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 60)

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username or Email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)

                            CustomTextField(
                                text: $viewModel.identifier,
                                placeholder: "Enter your username or email",
                                isSecure: false,
                                showToggle: false,
                                showAvailability: false,
                                isAvailable: nil,
                                isError: false
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Password")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                Spacer()

                                Button {
                                    showForgotPassword = true
                                } label: {
                                    Text("Forgot password?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.accentColor)
                                }
                            }

                            CustomTextField(
                                text: $viewModel.password,
                                placeholder: "Enter your password",
                                isSecure: true,
                                showToggle: true,
                                showAvailability: false,
                                isAvailable: nil,
                                isError: false
                            )
                        }
                    }
                    .padding(.top, 32)

                    PrimaryButton(
                        title: "Log In",
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.identifier.isEmpty || viewModel.password.isEmpty
                    ) {
                        Task {
                            await viewModel.login()
                        }
                    }
                    .padding(.top, 16)

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)

                        Button {
                            router.route = .register
                        } label: {
                            Text("Sign up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.didLogin) { _, newValue in
                if newValue {
                    preferences.isLoggedIn = true
                    router.route = .maintab
                }
            }
            .alert("Error", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView { email in
                    try await viewModel.sendPasswordReset(email: email)
                }
            }
        }
    }
}
