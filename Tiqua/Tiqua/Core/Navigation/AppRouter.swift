//
//  AppRouter.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter(prefs: AppPreferences.shared)

    @Published var route: AppRoute = .onboarding

    let prefs: AppPreferences
    init(prefs: AppPreferences) {
        self.prefs = prefs
        refreshRoute()
    }

    func refreshRoute() {
        if !prefs.hasSeenOnboarding { route = .onboarding; return }
        route = prefs.isLoggedIn ? .maintab : .login
    }
}

