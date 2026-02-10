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
    
    init() {
        FirebaseApp.configure() 
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
