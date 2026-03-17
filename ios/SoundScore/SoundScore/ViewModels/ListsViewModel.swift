import Foundation

class ListsViewModel: ObservableObject {
    @Published var lists: [UserList]
    @Published var showcases: [ListShowcase]
    @Published var syncMessage: String?

    private let albums: [Album]

    init() {
        self.albums = SeedData.albums
        self.lists = SeedData.initialLists
        self.showcases = resolveListShowcases(SeedData.initialLists, SeedData.albums)
        self.syncMessage = nil
    }

    func createList(title: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newList = UserList(
            id: "l_\(UUID().uuidString.prefix(8))",
            title: title,
            note: nil,
            albumIds: [],
            curatorHandle: "@madhav",
            saves: 0
        )
        lists.append(newList)
        showcases = resolveListShowcases(lists, albums)
    }
}
