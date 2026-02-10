//
//  AppRouter.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import Foundation
import Combine

final class AppRouter: ObservableObject {

    @Published var route: AppRoute = .onboarding

    func resolveInitialRoute() {
        if AppPreferences.shared.hasSeenOnboarding == false {
            route = .onboarding
        } else {
            route = .auth
        }
    }

    func finishOnboarding() {
        AppPreferences.shared.hasSeenOnboarding = true
        route = .auth
    }

    func didLogin() {
        AppPreferences.shared.isLoggedIn = true
        route = .home
    }

    func didLogout() {
        AppPreferences.shared.isLoggedIn = false
        route = .auth
    }
}
