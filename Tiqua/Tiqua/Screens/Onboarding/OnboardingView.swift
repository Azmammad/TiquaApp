//
//  OnboardingView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var preferences: AppPreferences
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Background Image
            Image("Onboarding")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Text("Tiqua")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.appPrimary)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : -40)
                    .animation(.easeOut(duration: 0.8), value: animate)
                
                Text("Share authentic travel\nexperiences from the places you visit")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 40)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : -20)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: animate)
                
                Spacer()
                
                VStack(spacing: 16) {
                    PrimaryButton(
                        title: "Get Started",
                        isLoading: false,
                        isDisabled: false
                    ) {
                        preferences.hasSeenOnboarding = true
                        router.route = .register
                    }
                    .opacity(animate ? 1 : 0)
                    .scaleEffect(animate ? 1 : 0.9)
                    .offset(y: animate ? 0 : 40)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: animate)
                    
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Button {
                            preferences.hasSeenOnboarding = true
                            router.route = .login
                        } label: {
                            Text("Log in")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appPrimary)
                        }
                    }
                    .opacity(animate ? 1 : 0)
                    .animation(.easeIn(duration: 1).delay(0.9), value: animate)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            animate = true
        }
    }
}
