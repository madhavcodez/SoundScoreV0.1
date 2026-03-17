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
        Album(
            id: "alb_7", title: "HIT ME HARD AND SOFT", artist: "Billie Eilish", year: 2024,
            artColors: AlbumColors.midnight, artworkUrl: nil, avgRating: 4.2, logCount: 1650
        ),
        Album(
            id: "alb_8", title: "The Tortured Poets Department", artist: "Taylor Swift", year: 2024,
            artColors: AlbumColors.slate, artworkUrl: nil, avgRating: 3.7, logCount: 2800
        ),
        Album(
            id: "alb_9", title: "Cowboy Carter", artist: "Beyoncé", year: 2024,
            artColors: AlbumColors.amber, artworkUrl: nil, avgRating: 4.4, logCount: 3100
        ),
        Album(
            id: "alb_10", title: "Romance", artist: "Fontaines D.C.", year: 2024,
            artColors: AlbumColors.forest, artworkUrl: nil, avgRating: 4.0, logCount: 780
        ),
        Album(
            id: "alb_11", title: "Lives Outgrown", artist: "Beth Gibbons", year: 2024,
            artColors: AlbumColors.orchid, artworkUrl: nil, avgRating: 4.1, logCount: 520
        ),
        Album(
            id: "alb_12", title: "Forever", artist: "Skrillex", year: 2024,
            artColors: AlbumColors.lagoon, artworkUrl: nil, avgRating: 3.6, logCount: 890
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
        FeedItem(
            id: "f4", username: "zara", action: "rated this on first listen",
            album: albums[6], rating: 4.5,
            reviewSnippet: "Billie went somewhere darker and it suits her perfectly.",
            likes: 31, comments: 5, timeAgo: "12h", isLiked: false
        ),
        FeedItem(
            id: "f5", username: "alex", action: "defended this in the group chat",
            album: albums[8], rating: 5.0,
            reviewSnippet: "Country + Beyoncé = genre-breaking territory.",
            likes: 42, comments: 11, timeAgo: "1d", isLiked: true
        ),
        FeedItem(
            id: "f6", username: "jordan", action: "added a hot take",
            album: albums[7], rating: 3.0,
            reviewSnippet: "The bonus tracks dilute what could've been a tight masterpiece.",
            likes: 15, comments: 9, timeAgo: "1d", isLiked: false
        ),
        FeedItem(
            id: "f7", username: "mia", action: "logged a quiet favorite",
            album: albums[10], rating: 4.5,
            reviewSnippet: "Beth Gibbons made the most patient album of the year.",
            likes: 9, comments: 2, timeAgo: "2d", isLiked: false
        ),
        FeedItem(
            id: "f8", username: "sam", action: "discovered a sleeper hit",
            album: albums[9], rating: 4.0,
            reviewSnippet: "Fontaines D.C. shifted gears and it completely works.",
            likes: 18, comments: 4, timeAgo: "3d", isLiked: true
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
        genres: ["Indie Sleaze", "Alt Rap", "Digital Pop", "Neo-Soul", "Late Night", "Country Futurism", "Post-Punk Revival", "Avg 4.1 ★"],
        avgRating: 4.1, albumsCount: 142,
        followingCount: 186, followersCount: 248,
        favoriteAlbums: [albums[0], albums[3], albums[8], albums[6], albums[4], albums[10]]
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
        UserList(id: "l4", title: "2024 Rap Monuments",
                 note: "The bars and beats that defined the year.",
                 albumIds: ["alb_1", "alb_2", "alb_9", "alb_7"], curatorHandle: "@alex", saves: 95),
        UserList(id: "l5", title: "Headphone Albums Only",
                 note: "Albums that demand isolation and full attention.",
                 albumIds: ["alb_5", "alb_11", "alb_7", "alb_6"], curatorHandle: "@madhav", saves: 112),
    ]

    static let defaultNotificationPreferences = NotificationPreferences()

    static let initialRecap = WeeklyRecap(
        id: "rcp_local", weekStart: "2026-03-03", weekEnd: "2026-03-10",
        totalLogs: 12, averageRating: 4.1,
        shareText: "My SoundScore week: 12 logs, avg 4.1★",
        deepLink: "https://soundscore.app/recaps/weekly/2026-03-03"
    )
}
