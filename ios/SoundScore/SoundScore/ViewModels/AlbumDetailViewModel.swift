import Foundation
import Combine

class AlbumDetailViewModel: ObservableObject {
    let album: Album

    @Published var tracks: [Track] = []
    @Published var trackRatings: [String: Float] = [:]
    @Published var userRating: Float = 0
    @Published var isLoadingTracks: Bool = true

    private var cancellables = Set<AnyCancellable>()

    init(album: Album) {
        self.album = album
        let repo = SoundScoreRepository.shared

        self.userRating = repo.ratings[album.id] ?? 0
        self.tracks = repo.tracksByAlbum[album.id] ?? []
        self.trackRatings = repo.trackRatings
        self.isLoadingTracks = tracks.isEmpty

        repo.$tracksByAlbum
            .receive(on: RunLoop.main)
            .map { $0[album.id] ?? [] }
            .sink { [weak self] newTracks in
                self?.tracks = newTracks
                if !newTracks.isEmpty {
                    self?.isLoadingTracks = false
                }
            }
            .store(in: &cancellables)

        repo.$trackRatings
            .receive(on: RunLoop.main)
            .assign(to: &$trackRatings)

        repo.$ratings
            .receive(on: RunLoop.main)
            .map { $0[album.id] ?? 0 }
            .assign(to: &$userRating)

        Task { await repo.fetchTracks(albumId: album.id) }
    }

    func updateAlbumRating(_ rating: Float) {
        userRating = rating
        SoundScoreRepository.shared.updateRating(albumId: album.id, rating: rating)
    }

    func updateTrackRating(trackId: String, rating: Float) {
        SoundScoreRepository.shared.updateTrackRating(
            trackId: trackId, albumId: album.id, rating: rating
        )
    }
}
