import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Album] = []
    @Published var browseGenres: [BrowseGenre]
    @Published var chartEntries: [ChartEntry]
    @Published var syncMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let albums: [Album]

    init() {
        self.albums = SeedData.albums
        self.browseGenres = buildBrowseGenres()
        self.chartEntries = buildChartEntries(SeedData.albums)
        self.syncMessage = nil

        $query
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] q in
                self?.performSearch(q)
            }
            .store(in: &cancellables)
    }

    func updateQuery(_ text: String) {
        query = text
    }

    private func performSearch(_ q: String) {
        if q.trimmingCharacters(in: .whitespaces).isEmpty {
            results = []
        } else {
            let lower = q.lowercased()
            results = albums.filter {
                $0.title.lowercased().contains(lower) || $0.artist.lowercased().contains(lower)
            }
        }
    }
}
