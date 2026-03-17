import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .feed
    @State private var selectedAlbum: Album?
    @State private var showSettings = false

    var body: some View {
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
        case .lists:
            ListsScreen(onSelectAlbum: onSelectAlbum)
        case .profile:
            ProfileScreen(onSelectAlbum: onSelectAlbum, onOpenSettings: onOpenSettings)
        }
    }
}

#Preview {
    ContentView()
}
