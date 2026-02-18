//
//  SettingsView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 18.02.26.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = SettingsViewModel()
    @State private var showLogoutConfirmation = false

    var body: some View {
        List {
            Section {
                Toggle("Dark Mode", isOn: $preferences.isDarkMode)
            } header: {
                Text("Appearance")
            }

            Section {
                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    HStack {
                        Text("Log Out")
                        Spacer()
                        if viewModel.isLoggingOut {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isLoggingOut)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Are you sure you want to log out?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                Task { await viewModel.logout() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: viewModel.didLogout) { _, newValue in
            if newValue {
                preferences.isLoggedIn = false
                router.route = .login
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}