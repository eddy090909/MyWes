//
//  MainTabView.swift
//  MyWes
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .appDestinations()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                DiscoverView()
                    .appDestinations()
            }
            .tabItem {
                Label("Discover", systemImage: "safari.fill")
            }
            .tag(1)

            NavigationStack {
                DiningView()
            }
            .tabItem {
                Label("Dining", systemImage: "fork.knife")
            }
            .tag(2)

            NavigationStack {
                AskWesView()
                    .appDestinations()
            }
            .tabItem {
                Label("AskWes", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(3)

            NavigationStack {
                ProfileView()
                    .appDestinations()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(4)
        }
        .tint(Theme.cardinal)
    }
}

#if DEBUG
#Preview {
    MainTabView()
        .environment(AppSession.preview())
}
#endif
