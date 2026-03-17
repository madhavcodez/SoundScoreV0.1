import Foundation
import Combine

class FeedViewModel: ObservableObject {
    @Published var items: [FeedItem]
    @Published var trendingAlbums: [Album]
    @Published var syncMessage: String?

    init() {
        let repo = SoundScoreRepository.shared
        self.items = repo.feedItems
        self.trendingAlbums = buildTrendingAlbums(repo.albums)
        self.syncMessage = repo.syncMessage

        repo.$feedItems
            .receive(on: RunLoop.main)
            .assign(to: &$items)

        repo.$albums
            .receive(on: RunLoop.main)
            .map { buildTrendingAlbums($0) }
            .assign(to: &$trendingAlbums)

        repo.$syncMessage
            .receive(on: RunLoop.main)
            .assign(to: &$syncMessage)
    }

    func toggleLike(_ id: String) {
        SoundScoreRepository.shared.toggleLike(feedItemId: id)
    }
}
