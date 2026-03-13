//
//  ForgotPasswordView.swift
//  Tiqua
//
//  Created by Generated on 11.02.26.
//
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isSuccess: Bool = false

    @Environment(\.dismiss) private var dismiss

    let onSubmit: (String) async throws -> String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Forgot Password")
                            .font(.system(size: 32, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.appPrimary)

                        Text("Enter your email address and we'll send you a link to reset your password")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)

                        CustomTextField(
                            text: $email,
                            placeholder: "your@email.com",
                            isSecure: false,
                            showToggle: false,
                            showAvailability: false,
                            isAvailable: nil,
                            isError: false
                        )
                    }
                    .padding(.top, 16)

                    PrimaryButton(
                        title: "Send Reset Link",
                        isLoading: isSubmitting,
                        isDisabled: email.isEmpty
                    ) {
                        Task {
                            await submit()
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func submit() async {
        guard !email.isEmpty else { return }
        isSubmitting = true

        do {
            let message = try await onSubmit(email)
            alertMessage = message
            isSuccess = true
        } catch {
            alertMessage = error.localizedDescription
            isSuccess = false
        }

        showAlert = true
        isSubmitting = false
    }
}
