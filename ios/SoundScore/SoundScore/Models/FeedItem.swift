import Foundation

struct FeedItem: Identifiable {
    let id: String
    let username: String
    let action: String
    var album: Album
    let rating: Float
    var reviewSnippet: String?
    var likes: Int
    var comments: Int
    var timeAgo: String
    var isLiked: Bool
}
