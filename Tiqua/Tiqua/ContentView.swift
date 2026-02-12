//
//  ContentView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import SwiftUI

struct ContentView: View {

    @EnvironmentObject var router: AppRouter

    var body: some View {
        switch router.route {
        case .onboarding:
            OnboardingView()
        case .login:
            LoginView()
        case .register:
            RegisterView()
        case .home:
            HomeView()
        }
    }
}

#Preview {
    ContentView()
}
