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

    //TODO: Login / Home ke,idi əlavə olunacaq
}
