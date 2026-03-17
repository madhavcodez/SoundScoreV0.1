import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var repository = SoundScoreRepository.shared
    @State private var selectedTab: Tab = .feed

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ZStack(alignment: .bottom) {
                    AppBackdrop()

                    TabContent(selectedTab: selectedTab)

                    FloatingTabBar(selectedTab: $selectedTab)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
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
    }
}

struct TabContent: View {
    let selectedTab: Tab

    var body: some View {
        switch selectedTab {
        case .feed:
            FeedScreen()
        case .log:
            LogScreen()
        case .search:
            SearchScreen()
        case .lists:
            ListsScreen()
        case .profile:
            ProfileScreen()
        }
    }
}

#Preview {
    ContentView()
}
