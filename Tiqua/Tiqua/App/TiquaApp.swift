//
//  TiquaApp.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import SwiftUI
import Firebase

@main
struct TiquaApp: App {
    @StateObject private var prefs: AppPreferences
    @StateObject private var router: AppRouter

    init() {
        FirebaseApp.configure()
        let prefs = AppPreferences()
        _prefs = StateObject(wrappedValue: prefs)
        _router = StateObject(wrappedValue: AppRouter(prefs: prefs))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(prefs)
                .environmentObject(router)
                .preferredColorScheme(prefs.isDarkMode ? .dark : .light)
        }
    }
}
