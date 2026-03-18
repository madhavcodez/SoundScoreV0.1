import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Album] = []
    @Published var browseGenres: [BrowseGenre]
    @Published var chartEntries: [ChartEntry]
    @Published var syncMessage: String?
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init() {
        let repo = SoundScoreRepository.shared
        self.browseGenres = buildBrowseGenres()
        self.chartEntries = buildChartEntries(repo.albums)
        self.syncMessage = repo.syncMessage
        self.errorMessage = repo.errorMessage

        $query
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] q in
                self?.performSearch(q)
            }
            .store(in: &cancellables)

        repo.$albums
            .receive(on: RunLoop.main)
            .map { buildChartEntries($0) }
            .assign(to: &$chartEntries)

        repo.$syncMessage
            .receive(on: RunLoop.main)
            .assign(to: &$syncMessage)

        repo.$errorMessage
            .receive(on: RunLoop.main)
            .assign(to: &$errorMessage)
    }

    func updateQuery(_ text: String) {
        query = text
    }

    private func performSearch(_ q: String) {
        searchTask?.cancel()

        let trimmed = q.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            results = []
            isSearching = false
            return
        }

        isSearching = true

        // Local results first
        let localResults = SoundScoreRepository.shared.searchAlbums(query: trimmed)

        searchTask = Task { @MainActor in
            // Show local results immediately
            self.results = localResults

            // Then fetch Spotify results and merge
            let spotifyResults = await SpotifyService.shared.searchAlbums(query: trimmed, limit: 5)
            guard !Task.isCancelled else { return }

            let localIds = Set(localResults.map { "\($0.title.lowercased())|\($0.artist.lowercased())" })
            let remoteAlbums = spotifyResults.compactMap { result -> Album? in
                let key = "\(result.title.lowercased())|\(result.artist.lowercased())"
                guard !localIds.contains(key) else { return nil }
                return Album(
                    id: "spot_\(result.spotifyId)",
                    title: result.title,
                    artist: result.artist,
                    year: result.year,
                    artColors: AlbumColors.forest,
                    artworkUrl: result.artworkUrl,
                    avgRating: 0,
                    logCount: 0
                )
            }

            self.results = localResults + remoteAlbums
            self.isSearching = false
        }
    }
}
