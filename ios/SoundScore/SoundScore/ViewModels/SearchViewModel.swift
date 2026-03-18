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

    init() {
        let repo = SoundScoreRepository.shared
        self.browseGenres = buildBrowseGenres()
        self.chartEntries = buildChartEntries(repo.albums)
        self.syncMessage = repo.syncMessage
        self.errorMessage = repo.errorMessage

        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
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
        let trimmed = q.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            results = []
            isSearching = false
        } else {
            isSearching = true
            results = SoundScoreRepository.shared.searchAlbums(query: trimmed)
            isSearching = false
        }
    }
}
