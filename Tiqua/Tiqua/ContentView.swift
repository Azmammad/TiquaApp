//
//  ContentView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import SwiftUI

struct ContentView: View {

    @StateObject private var router = AppRouter()

    var body: some View {
        Group {
            switch router.route {
            case .onboarding:
                OnboardingView {
                    router.finishOnboarding()
                }

            case .auth:
                LoginView()

            case .home:
                Text("Home")
            }
        }
        .onAppear {
            router.resolveInitialRoute()
        }
    }
}

#Preview {
    ContentView()
}
