//
//  RegisterView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = RegisterViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.appPrimary)

                        
                        Text("Join Tiqua and start sharing your authentic travel experiences")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 24)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            CustomTextField(
                                text: $viewModel.username,
                                placeholder: "Choose a unique username",
                                isSecure: false,
                                showToggle: false,
                                showAvailability: true,
                                isAvailable: viewModel.isUsernameAvailable,
                                isError: false
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            CustomTextField(
                                text: $viewModel.email,
                                placeholder: "your@email.com",
                                isSecure: false,
                                showToggle: false,
                                showAvailability: false,
                                isAvailable: nil,
                                isError: false
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            CustomTextField(
                                text: $viewModel.password,
                                placeholder: "At least 8 characters",
                                isSecure: true,
                                showToggle: true,
                                showAvailability: false,
                                isAvailable: nil,
                                isError: false
                            )
                        }
                    }
                    
                    Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    PrimaryButton(
                        title: "Create Account",
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.username.isEmpty || viewModel.email.isEmpty || viewModel.password.isEmpty
                    ) {
                        Task {
                            await viewModel.register()
                        }
                    }
                    .padding(.top, 8)
                    
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Button {
                            router.route = .login
                        } label: {
                            Text("Log in")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        router.route = .onboarding
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .onChange(of: viewModel.didRegisterSuccessfully) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        router.route = .login
                    }
                }
            }
            .alert(
                viewModel.didRegisterSuccessfully ? "Success" : "Error",
                isPresented: $viewModel.showAlert
            ) {
                Button("OK", role: .cancel) {
                    if viewModel.didRegisterSuccessfully {
                        router.route = .login
                    }
                }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

