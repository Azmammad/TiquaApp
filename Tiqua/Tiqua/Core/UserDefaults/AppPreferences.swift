//
//  UserDefaultsManager.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import Foundation

final class AppPreferences {

    static let shared = AppPreferences()
    private init() {}

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasSeenOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasSeenOnboarding) }
    }
}

