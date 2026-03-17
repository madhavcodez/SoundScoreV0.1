import Foundation

class FeedViewModel: ObservableObject {
    @Published var items: [FeedItem]
    @Published var trendingAlbums: [Album]
    @Published var syncMessage: String?

    init() {
        self.items = SeedData.feedItems
        self.trendingAlbums = buildTrendingAlbums(SeedData.albums)
        self.syncMessage = nil
    }

    func toggleLike(_ id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isLiked.toggle()
        items[index].likes += items[index].isLiked ? 1 : -1
    }
}
