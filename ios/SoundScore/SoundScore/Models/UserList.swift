import Foundation

struct UserList: Identifiable {
    let id: String
    let title: String
    var note: String?
    var albumIds: [String]
    var curatorHandle: String
    var saves: Int
}
