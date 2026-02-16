//
//  ProfileView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 13.02.26.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.accentColor)
                        
                        Text("Your Profile")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("Manage your account and preferences")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Logout Button
                    Button {
                        logout()
                    } label: {
                        Text("Log Out")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func logout() {
        Task {
            do {
                try await FirebaseAuthService().logout()
                preferences.isLoggedIn = false
                router.route = .login
            } catch {
                print("Logout error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter.shared)
        .environmentObject(AppPreferences.shared)
}
