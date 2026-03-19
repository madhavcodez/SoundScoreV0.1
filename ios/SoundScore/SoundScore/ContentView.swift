import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var repository = SoundScoreRepository.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab: Tab = .feed
    @State private var selectedAlbum: Album?
    @State private var showSettings = false
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashScreen {
                    showSplash = false
                }
                .transition(.opacity)
            } else if authManager.isAuthenticated {
                NavigationStack {
                    ZStack(alignment: .bottom) {
                        AppBackdrop()

                        TabContent(
                            selectedTab: selectedTab,
                            onSelectAlbum: { selectedAlbum = $0 },
                            onOpenSettings: { showSettings = true }
                        )

                        FloatingTabBar(selectedTab: $selectedTab)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                    }
                    .navigationDestination(item: $selectedAlbum) { album in
                        AlbumDetailScreen(album: album)
                    }
                    .navigationDestination(isPresented: $showSettings) {
                        SettingsScreen()
                    }
                }
            } else {
                ZStack {
                    AppBackdrop()
                    AuthScreen()
                }
            }
        }
        .environmentObject(authManager)
        .environmentObject(repository)
        .environmentObject(ThemeManager.shared)
    }
}

struct TabContent: View {
    let selectedTab: Tab
    var onSelectAlbum: (Album) -> Void = { _ in }
    var onOpenSettings: () -> Void = {}

    var body: some View {
        switch selectedTab {
        case .feed:
            FeedScreen(onSelectAlbum: onSelectAlbum)
        case .log:
            LogScreen(onSelectAlbum: onSelectAlbum)
        case .search:
            SearchScreen(onSelectAlbum: onSelectAlbum)
        case .aiBuddy:
            AIBuddyScreen()
        case .profile:
            ProfileScreen(onSelectAlbum: onSelectAlbum, onOpenSettings: onOpenSettings)
        }
    }
}

#Preview {
    ContentView()
}
