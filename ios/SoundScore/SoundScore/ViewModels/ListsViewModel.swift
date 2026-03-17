import Foundation
import Combine

class ListsViewModel: ObservableObject {
    @Published var lists: [UserList]
    @Published var showcases: [ListShowcase]
    @Published var syncMessage: String?

    init() {
        let repo = SoundScoreRepository.shared
        self.lists = repo.lists
        self.showcases = resolveListShowcases(repo.lists, repo.albums)
        self.syncMessage = repo.syncMessage

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
    }

    func createList(title: String) {
        SoundScoreRepository.shared.createList(title: title)
    }
}
