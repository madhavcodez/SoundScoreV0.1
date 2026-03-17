import Foundation

struct UserProfile {
    let handle: String
    let bio: String
    let logCount: Int
    let reviewCount: Int
    let listCount: Int
    let topAlbums: [(Album, Float)]
    let genres: [String]
    let avgRating: Float
    var albumsCount: Int
    var followingCount: Int
    var followersCount: Int
    var favoriteAlbums: [Album]
}
