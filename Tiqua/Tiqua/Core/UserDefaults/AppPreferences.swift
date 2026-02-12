//
//  UserDefaultsManager.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import Foundation
import Combine

final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    @Published var hasSeenOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.onboarding) }
    }

    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: Keys.loggedIn) }
    }

    @Published var isDarkMode: Bool {
        didSet { UserDefaults.standard.set(isDarkMode, forKey: Keys.darkMode) }
    }

    private enum Keys {
        static let onboarding = "hasSeenOnboarding"
        static let loggedIn = "isLoggedIn"
        static let darkMode = "isDarkMode"
    }

    init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: Keys.onboarding)
        self.isLoggedIn = UserDefaults.standard.bool(forKey: Keys.loggedIn)
        self.isDarkMode = UserDefaults.standard.bool(forKey: Keys.darkMode)
    }
}



