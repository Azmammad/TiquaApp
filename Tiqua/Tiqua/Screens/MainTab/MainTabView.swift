//
//  MainTabView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 14.02.26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case create
        case saved
        case profile
    }
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == .home ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(Tab.home)
            
            CreateView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Create")
                }
                .tag(Tab.create)
            
            SavedView()
                .tabItem {
                    Image(systemName: selectedTab == .saved ? "bookmark.fill" : "bookmark")
                    Text("Saved")
                }
                .tag(Tab.saved)
            
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(Tab.profile)
        }
        .tint(.inside)
    }
}


#Preview {
    MainTabView()
}
