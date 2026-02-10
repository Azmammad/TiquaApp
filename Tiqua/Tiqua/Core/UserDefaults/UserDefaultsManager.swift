//
//  UserDefaultsManager.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private init() {}

    private let isLoggedInKey = "isLoggedIn"
    private let didSeeOnboardingKey = "didSeeOnboarding"

    var isLoggedIn: Bool {
        get { UserDefaults.standard.bool(forKey: isLoggedInKey) }
        set { UserDefaults.standard.set(newValue, forKey: isLoggedInKey) }
    }

    var didSeeOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: didSeeOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: didSeeOnboardingKey) }
    }
}
