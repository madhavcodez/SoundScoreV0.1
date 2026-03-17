import SwiftUI

enum SeedData {
    private static func hiRes(_ url: String) -> String {
        url.replacingOccurrences(of: "100x100bb.jpg", with: "600x600bb.jpg")
           .replacingOccurrences(of: "100x100bb.png", with: "600x600bb.png")
    }

    static let albums: [Album] = [
        Album(
            id: "alb_1", title: "CHROMAKOPIA", artist: "Tyler, the Creator", year: 2024,
            artColors: AlbumColors.forest,
            artworkUrl: hiRes("https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/b6/ef/ee/b6efeefa-fc99-37d1-ad21-0d769b2a4958/196872796971.jpg/100x100bb.jpg"),
            avgRating: 4.3, logCount: 2100
        ),
        Album(
            id: "alb_2", title: "GNX", artist: "Kendrick Lamar", year: 2024,
            artColors: AlbumColors.midnight,
            artworkUrl: hiRes("https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/54/28/14/54281424-eece-0935-299d-fdd2ab403f92/24UM1IM28978.rgb.jpg/100x100bb.jpg"),
            avgRating: 4.1, logCount: 1800
        ),
        Album(
            id: "alb_3", title: "Short n' Sweet", artist: "Sabrina Carpenter", year: 2024,
            artColors: AlbumColors.lime,
            artworkUrl: hiRes("https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/a1/1c/ca/a11ccab6-7d4c-e041-d028-998bcebeb709/24UMGIM61704.rgb.jpg/100x100bb.jpg"),
            avgRating: 3.8, logCount: 950
        ),
        Album(
            id: "alb_4", title: "Brat", artist: "Charli XCX", year: 2024,
            artColors: AlbumColors.rose, artworkUrl: nil, avgRating: 4.0, logCount: 3200
        ),
        Album(
            id: "alb_5", title: "Manning Fireside", artist: "Mk.gee", year: 2024,
            artColors: AlbumColors.lagoon, artworkUrl: nil, avgRating: 3.9, logCount: 620
        ),
        Album(
            id: "alb_6", title: "The Great Impersonator", artist: "Halsey", year: 2024,
            artColors: AlbumColors.ember, artworkUrl: nil, avgRating: 3.5, logCount: 430
        ),
    ]

    static let feedItems: [FeedItem] = [
        FeedItem(
            id: "f1", username: "rohan", action: "logged a perfect score",
            album: albums[0], rating: 5.0,
            reviewSnippet: "Tyler made a world, not just a tracklist.",
            likes: 12, comments: 3, timeAgo: "2h", isLiked: true
        ),
        FeedItem(
            id: "f2", username: "priya", action: "left a glowing review",
            album: albums[2], rating: 4.0,
            reviewSnippet: "Hooks for days, but the production is what sticks.",
            likes: 8, comments: 1, timeAgo: "5h", isLiked: false
        ),
        FeedItem(
            id: "f3", username: "kai", action: "added this to a late-night list",
            album: albums[3], rating: 4.5,
            reviewSnippet: "The whole thing feels fluorescent and slightly dangerous.",
            likes: 24, comments: 7, timeAgo: "8h", isLiked: false
        ),
    ]

    static let logInitialRatings: [String: Float] = [
        "alb_1": 5, "alb_2": 4.5, "alb_3": 4, "alb_4": 4.5,
    ]

    static let myProfile = UserProfile(
        handle: "@madhav",
        bio: "Taste journal for records worth replaying at 1 a.m.",
        logCount: 142, reviewCount: 38, listCount: 24,
        topAlbums: [
            (albums[0], 5.0), (albums[2], 4.5), (albums[3], 4.5),
            (albums[4], 4.0), (albums[5], 4.0), (albums[1], 3.5),
        ],
        genres: ["Indie Sleaze", "Alt Rap", "Digital Pop", "Neo-Soul", "Late Night", "Avg 4.1 ★"],
        avgRating: 4.1, albumsCount: 142,
        followingCount: 186, followersCount: 248,
        favoriteAlbums: [albums[0], albums[3], albums[2], albums[1], albums[4], albums[5]]
    )

    static let initialLists: [UserList] = [
        UserList(id: "l1", title: "Albums I Would Defend",
                 note: "Chaotic, immediate, impossible to half-love.",
                 albumIds: ["alb_4", "alb_1", "alb_2", "alb_3"], curatorHandle: "@madhav", saves: 128),
        UserList(id: "l2", title: "Midnight Headphones",
                 note: "For the train ride home when the city still feels loud.",
                 albumIds: ["alb_5", "alb_6", "alb_1", "alb_2"], curatorHandle: "@priya", saves: 84),
        UserList(id: "l3", title: "2024 Pop Mutations",
                 note: "Big hooks, weird textures, zero safe choices.",
                 albumIds: ["alb_3", "alb_4", "alb_2", "alb_1"], curatorHandle: "@kai", saves: 67),
    ]

    static let defaultNotificationPreferences = NotificationPreferences()

    static let initialRecap = WeeklyRecap(
        id: "rcp_local", weekStart: "2026-03-03", weekEnd: "2026-03-10",
        totalLogs: 12, averageRating: 4.1,
        shareText: "My SoundScore week: 12 logs, avg 4.1★",
        deepLink: "https://soundscore.app/recaps/weekly/2026-03-03"
    )
}
