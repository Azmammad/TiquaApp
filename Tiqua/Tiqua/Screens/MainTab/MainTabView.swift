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
        case map
        case create
        case activity
        case profile
    }
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == .home ? "house.fill" : "house")
                }
                .tag(Tab.home)
            
            NavigationStack {
                MapScreenView()
            }
                .tabItem {
                    Image(systemName: selectedTab == .map ? "map.fill" : "map")
                }
                .tag(Tab.map)
            
            CreatePostView(switchToTab: $selectedTab)
                .tabItem {
                    Image(systemName: "plus.app")
                }
                .tag(Tab.create)
            
            ActivityView()
                .tabItem {
                    Image(systemName: selectedTab == .activity ? "bell.fill" : "bell")
                }
                .tag(Tab.activity)
            
            ProfileView(switchToTab: $selectedTab)
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                }
                .tag(Tab.profile)
        }
        .tint(.inside)
    }
}


#Preview {
    MainTabView()
}
