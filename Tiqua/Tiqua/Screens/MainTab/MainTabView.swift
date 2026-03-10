//
//  MainTabView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 14.02.26.
//
import SwiftUI
import Combine

@MainActor
final class MapFocusState: ObservableObject {
    @Published var focusedLatitude: Double?
    @Published var focusedLongitude: Double?
    @Published var focusedLocationName: String?
    @Published var shouldSwitchToMap: Bool = false

    var hasFocus: Bool {
        focusedLatitude != nil && focusedLongitude != nil
    }

    func focusOn(latitude: Double, longitude: Double, locationName: String?) {
        focusedLatitude = latitude
        focusedLongitude = longitude
        focusedLocationName = locationName
        shouldSwitchToMap = true
    }

    func clearFocus() {
        focusedLatitude = nil
        focusedLongitude = nil
        focusedLocationName = nil
        shouldSwitchToMap = false
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @StateObject private var mapFocusState = MapFocusState()

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
        .environmentObject(mapFocusState)
        .onChange(of: mapFocusState.shouldSwitchToMap) { _, newValue in
            if newValue {
                selectedTab = .map
                mapFocusState.shouldSwitchToMap = false
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .map {
                mapFocusState.clearFocus()
            }
        }
    }
}


#Preview {
    MainTabView()
}
