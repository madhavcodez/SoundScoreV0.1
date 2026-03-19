import Foundation
import Combine

class FeedViewModel: ObservableObject {
    @Published var items: [FeedItem]
    @Published var trendingAlbums: [Album]
    @Published var trendingSongs: [TrendingSong]
    @Published var featuredLists: [ListShowcase]
    @Published var syncMessage: String?
    @Published var isLoading: Bool
    @Published var errorMessage: String?

    init() {
        let repo = SoundScoreRepository.shared
        self.items = repo.feedItems
        self.trendingAlbums = buildTrendingAlbums(repo.albums)
        self.trendingSongs = buildTrendingSongs(
            tracksByAlbum: repo.tracksByAlbum,
            trackRatings: repo.trackRatings,
            albums: repo.albums
        )
        self.featuredLists = resolveListShowcases(repo.lists, repo.albums)
        self.syncMessage = repo.syncMessage
        self.isLoading = repo.isLoading
        self.errorMessage = repo.errorMessage

        repo.$feedItems
            .receive(on: RunLoop.main)
            .assign(to: &$items)

        repo.$albums
            .receive(on: RunLoop.main)
            .map { buildTrendingAlbums($0) }
            .assign(to: &$trendingAlbums)

        Publishers.CombineLatest3(repo.$tracksByAlbum, repo.$trackRatings, repo.$albums)
            .receive(on: RunLoop.main)
            .map { buildTrendingSongs(tracksByAlbum: $0, trackRatings: $1, albums: $2) }
            .assign(to: &$trendingSongs)

        Publishers.CombineLatest(repo.$lists, repo.$albums)
            .receive(on: RunLoop.main)
            .map { resolveListShowcases($0, $1) }
            .assign(to: &$featuredLists)

        repo.$syncMessage
            .receive(on: RunLoop.main)
            .assign(to: &$syncMessage)

        repo.$isLoading
            .receive(on: RunLoop.main)
            .assign(to: &$isLoading)

        repo.$errorMessage
            .receive(on: RunLoop.main)
            .assign(to: &$errorMessage)
    }

    func toggleLike(_ id: String) {
        SoundScoreRepository.shared.toggleLike(feedItemId: id)
    }

    func refresh() {
        Task { await SoundScoreRepository.shared.refresh() }
    }
}
