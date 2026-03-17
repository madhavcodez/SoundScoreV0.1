import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .feed

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackdrop()

            TabContent(selectedTab: selectedTab)

            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
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
