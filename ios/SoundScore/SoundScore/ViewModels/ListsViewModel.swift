import Foundation
import Combine

class ListsViewModel: ObservableObject {
    @Published var lists: [UserList]
    @Published var showcases: [ListShowcase]
    @Published var syncMessage: String?
    @Published var isLoading: Bool
    @Published var errorMessage: String?

    init() {
        let repo = SoundScoreRepository.shared
        self.lists = repo.lists
        self.showcases = resolveListShowcases(repo.lists, repo.albums)
        self.syncMessage = repo.syncMessage
        self.isLoading = repo.isLoading
        self.errorMessage = repo.errorMessage

        repo.$lists
            .receive(on: RunLoop.main)
            .assign(to: &$lists)

        Publishers.CombineLatest(repo.$lists, repo.$albums)
            .receive(on: RunLoop.main)
            .map { resolveListShowcases($0, $1) }
            .assign(to: &$showcases)

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

    func createList(title: String) {
        SoundScoreRepository.shared.createList(title: title)
    }
}
