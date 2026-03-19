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
            avgRating: 4.3, logCount: 2100,
            genres: ["Hip-Hop", "Art Rap", "Neo-Soul"]
        ),
        Album(
            id: "alb_2", title: "GNX", artist: "Kendrick Lamar", year: 2024,
            artColors: AlbumColors.midnight,
            artworkUrl: hiRes("https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/54/28/14/54281424-eece-0935-299d-fdd2ab403f92/24UM1IM28978.rgb.jpg/100x100bb.jpg"),
            avgRating: 4.1, logCount: 1800,
            genres: ["Hip-Hop", "West Coast Rap", "Conscious Rap"]
        ),
        Album(
            id: "alb_3", title: "Short n' Sweet", artist: "Sabrina Carpenter", year: 2024,
            artColors: AlbumColors.lime,
            artworkUrl: hiRes("https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/a1/1c/ca/a11ccab6-7d4c-e041-d028-998bcebeb709/24UMGIM61704.rgb.jpg/100x100bb.jpg"),
            avgRating: 3.8, logCount: 950,
            genres: ["Pop", "Dance Pop", "Synth Pop"]
        ),
        Album(
            id: "alb_4", title: "Brat", artist: "Charli XCX", year: 2024,
            artColors: AlbumColors.rose,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b273f88b43d15fd14e9525338b59",
            avgRating: 4.0, logCount: 3200,
            genres: ["Hyperpop", "Electroclash", "Dance Pop"]
        ),
        Album(
            id: "alb_5", title: "Manning Fireside", artist: "Mk.gee", year: 2024,
            artColors: AlbumColors.lagoon,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b2732a8e8b10d2ada6d5a9a459a8",
            avgRating: 3.9, logCount: 620,
            genres: ["Indie Rock", "Art Pop", "Lo-Fi"]
        ),
        Album(
            id: "alb_6", title: "The Great Impersonator", artist: "Halsey", year: 2024,
            artColors: AlbumColors.ember,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b2732e53476c915af358ba2aac02",
            avgRating: 3.5, logCount: 430,
            genres: ["Alt Pop", "Indie Pop", "Electropop"]
        ),
        Album(
            id: "alb_7", title: "HIT ME HARD AND SOFT", artist: "Billie Eilish", year: 2024,
            artColors: AlbumColors.midnight,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b27371d62ea7ea8a5be92d3c1f62",
            avgRating: 4.2, logCount: 1650,
            genres: ["Alt Pop", "Dark Pop", "Electronica"]
        ),
        Album(
            id: "alb_8", title: "The Tortured Poets Department", artist: "Taylor Swift", year: 2024,
            artColors: AlbumColors.slate,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b2738ecc33f195df6aa257c39eaa",
            avgRating: 3.7, logCount: 2800,
            genres: ["Pop", "Indie Folk", "Singer-Songwriter"]
        ),
        Album(
            id: "alb_9", title: "Cowboy Carter", artist: "Beyoncé", year: 2024,
            artColors: AlbumColors.amber,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b273208e593c3565dae1295b5a26",
            avgRating: 4.4, logCount: 3100,
            genres: ["Country", "R&B", "Americana"]
        ),
        Album(
            id: "alb_10", title: "Romance", artist: "Fontaines D.C.", year: 2024,
            artColors: AlbumColors.forest,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b273f69e28716be1331924f25f2e",
            avgRating: 4.0, logCount: 780,
            genres: ["Post-Punk", "Indie Rock", "Art Rock"]
        ),
        Album(
            id: "alb_11", title: "Lives Outgrown", artist: "Beth Gibbons", year: 2024,
            artColors: AlbumColors.orchid,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b27316997b4a53ae6b42a4b803be",
            avgRating: 4.1, logCount: 520,
            genres: ["Art Rock", "Chamber Pop", "Experimental"]
        ),
        Album(
            id: "alb_12", title: "Forever", artist: "Skrillex", year: 2024,
            artColors: AlbumColors.lagoon,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b2732a7e34a68952017d900c6bb8",
            avgRating: 3.6, logCount: 890,
            genres: ["EDM", "Bass Music", "Dubstep"]
        ),
        // Additional albums for variety
        Album(
            id: "alb_13", title: "Imaginal Disk", artist: "Magdalena Bay", year: 2024,
            artColors: AlbumColors.orchid,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b27305b2a7c275c1b835a1377527",
            avgRating: 4.3, logCount: 670,
            genres: ["Synth Pop", "Art Pop", "Dream Pop"]
        ),
        Album(
            id: "alb_14", title: "Bright Future", artist: "Adrianne Lenker", year: 2024,
            artColors: AlbumColors.lime,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b273f098384079cd03e3aa70f946",
            avgRating: 4.0, logCount: 410,
            genres: ["Indie Folk", "Singer-Songwriter", "Acoustic"]
        ),
        Album(
            id: "alb_15", title: "Eternal Sunshine", artist: "Ariana Grande", year: 2024,
            artColors: AlbumColors.rose,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b273143e0e1cce5196c93aaabb61",
            avgRating: 3.7, logCount: 2400,
            genres: ["Pop", "R&B", "Dance Pop"]
        ),
        Album(
            id: "alb_16", title: "Only God Was Above Us", artist: "Vampire Weekend", year: 2024,
            artColors: AlbumColors.slate,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b2730c8cfff6a5e1e5771bd3f9f4",
            avgRating: 3.9, logCount: 560,
            genres: ["Indie Rock", "Art Rock", "Baroque Pop"]
        ),
        Album(
            id: "alb_17", title: "Passages", artist: "Khruangbin", year: 2024,
            artColors: AlbumColors.amber,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b27309fbbfe23e142c0d3e9bcaab",
            avgRating: 3.8, logCount: 480,
            genres: ["Psychedelic", "World Music", "Funk"]
        ),
        Album(
            id: "alb_18", title: "Blue Electric Light", artist: "Lenny Kravitz", year: 2024,
            artColors: AlbumColors.lagoon,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b2738b7c3ceaa0951d5e74d93e64",
            avgRating: 3.4, logCount: 320,
            genres: ["Rock", "Funk Rock", "Blues Rock"]
        ),
        Album(
            id: "alb_19", title: "Timeless", artist: "Kaytranada", year: 2024,
            artColors: AlbumColors.coral,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b2733ee87fd7666cb40f2a281e87",
            avgRating: 4.2, logCount: 740,
            genres: ["Electronic", "House", "R&B"]
        ),
        Album(
            id: "alb_20", title: "Wall of Eyes", artist: "The Smile", year: 2024,
            artColors: AlbumColors.midnight,
            artworkUrl: "https://i.scdn.co/image/ab67616d0000b273d3a38bbdec5907ea7028d845",
            avgRating: 4.1, logCount: 510,
            genres: ["Art Rock", "Experimental", "Post-Punk"]
        ),
    ]

    static let feedItems: [FeedItem] = [
        FeedItem(
            id: "f1", username: "rohan", action: "logged a perfect score",
            album: albums[0], rating: 5.0,
            reviewSnippet: "Tyler made a world, not just a tracklist. The Lil Wayne feature on St. Chroma alone is worth the price of admission — production-wise this might be his most ambitious yet.",
            likes: 12, comments: 3, timeAgo: "2h", isLiked: true
        ),
        FeedItem(
            id: "f2", username: "priya", action: "left a glowing review",
            album: albums[2], rating: 4.0,
            reviewSnippet: "Hooks for days, but the production is what sticks. The way 'Espresso' builds that bass line under the hook is pure sugar rush.",
            likes: 8, comments: 1, timeAgo: "5h", isLiked: false
        ),
        FeedItem(
            id: "f3", username: "kai", action: "added this to a late-night playlist",
            album: albums[3], rating: 4.5,
            reviewSnippet: "The whole thing feels fluorescent and slightly dangerous. 'Von Dutch' has that A.G. Cook production DNA that makes everything feel like it's melting.",
            likes: 24, comments: 7, timeAgo: "8h", isLiked: false
        ),
        FeedItem(
            id: "f4", username: "zara", action: "rated this on first listen",
            album: albums[6], rating: 4.5,
            reviewSnippet: "Billie went somewhere darker and it suits her perfectly. FINNEAS really outdid himself on the mixing — headphones mandatory.",
            likes: 31, comments: 5, timeAgo: "12h", isLiked: false
        ),
        FeedItem(
            id: "f5", username: "alex", action: "defended this in the group chat",
            album: albums[8], rating: 5.0,
            reviewSnippet: "Country + Beyoncé = genre-breaking territory. '16 Carriages' is the kind of song that makes you rethink an entire genre. The Dolly feature is exactly what this album deserved.",
            likes: 42, comments: 11, timeAgo: "1d", isLiked: true
        ),
        FeedItem(
            id: "f6", username: "jordan", action: "posted a hot take",
            album: albums[7], rating: 3.0,
            reviewSnippet: "The bonus tracks dilute what could've been a tight masterpiece. First 16 tracks? Excellent. The anthology edition? Taylor, we love you, but editorial restraint is also an art.",
            likes: 15, comments: 9, timeAgo: "1d", isLiked: false
        ),
        FeedItem(
            id: "f7", username: "mia", action: "logged a quiet favorite",
            album: albums[10], rating: 4.5,
            reviewSnippet: "Beth Gibbons made the most patient album of the year. Every note feels like it was placed with surgical precision. Not for the casual listener — this is headphone-and-lights-off territory.",
            likes: 9, comments: 2, timeAgo: "2d", isLiked: false
        ),
        FeedItem(
            id: "f8", username: "sam", action: "discovered a sleeper hit",
            album: albums[9], rating: 4.0,
            reviewSnippet: "Fontaines D.C. shifted gears and it completely works. The fact they named it 'Romance' while making their most abrasive record yet is peak irony.",
            likes: 18, comments: 4, timeAgo: "3d", isLiked: true
        ),
        FeedItem(
            id: "f9", username: "nina", action: "couldn't stop replaying",
            album: albums[12], rating: 4.5,
            reviewSnippet: "Magdalena Bay's synth work on this is unreal. 'Image' has that Tears for Fears energy but filtered through a Y2K screensaver. Peak vibes.",
            likes: 27, comments: 6, timeAgo: "3d", isLiked: false
        ),
        FeedItem(
            id: "f10", username: "dex", action: "rated between sets",
            album: albums[18], rating: 4.0,
            reviewSnippet: "Kaytranada never misses. The groove on every track is so locked in. Perfect house party starter pack — just press play and let it ride.",
            likes: 33, comments: 8, timeAgo: "4d", isLiked: true
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

    static let sampleTracks: [String: [Track]] = [
        "alb_1": [
            Track(id: "t1_1", albumId: "alb_1", title: "St. Chroma", trackNumber: 1, durationMs: 218_000, spotifyId: nil),
            Track(id: "t1_2", albumId: "alb_1", title: "Rah Tah Tah", trackNumber: 2, durationMs: 156_000, spotifyId: nil),
            Track(id: "t1_3", albumId: "alb_1", title: "Noid", trackNumber: 3, durationMs: 203_000, spotifyId: nil),
            Track(id: "t1_4", albumId: "alb_1", title: "Darling, I", trackNumber: 4, durationMs: 247_000, spotifyId: nil),
            Track(id: "t1_5", albumId: "alb_1", title: "Hey Jane", trackNumber: 5, durationMs: 261_000, spotifyId: nil),
            Track(id: "t1_6", albumId: "alb_1", title: "I Killed You", trackNumber: 6, durationMs: 189_000, spotifyId: nil),
            Track(id: "t1_7", albumId: "alb_1", title: "Judge Judy", trackNumber: 7, durationMs: 174_000, spotifyId: nil),
            Track(id: "t1_8", albumId: "alb_1", title: "Sticky", trackNumber: 8, durationMs: 210_000, spotifyId: nil),
            Track(id: "t1_9", albumId: "alb_1", title: "Take Your Mask Off", trackNumber: 9, durationMs: 228_000, spotifyId: nil),
            Track(id: "t1_10", albumId: "alb_1", title: "Tomorrow", trackNumber: 10, durationMs: 195_000, spotifyId: nil),
            Track(id: "t1_11", albumId: "alb_1", title: "Thought I Was Dead", trackNumber: 11, durationMs: 262_000, spotifyId: nil),
            Track(id: "t1_12", albumId: "alb_1", title: "Like Him", trackNumber: 12, durationMs: 314_000, spotifyId: nil),
            Track(id: "t1_13", albumId: "alb_1", title: "Balloon", trackNumber: 13, durationMs: 241_000, spotifyId: nil),
            Track(id: "t1_14", albumId: "alb_1", title: "I Hope You Find Your Way Home", trackNumber: 14, durationMs: 198_000, spotifyId: nil),
        ],
        "alb_2": [
            Track(id: "t2_1", albumId: "alb_2", title: "wacced out murals", trackNumber: 1, durationMs: 325_000, spotifyId: nil),
            Track(id: "t2_2", albumId: "alb_2", title: "squabble up", trackNumber: 2, durationMs: 152_000, spotifyId: nil),
            Track(id: "t2_3", albumId: "alb_2", title: "luther", trackNumber: 3, durationMs: 268_000, spotifyId: nil),
            Track(id: "t2_4", albumId: "alb_2", title: "tv off", trackNumber: 4, durationMs: 276_000, spotifyId: nil),
            Track(id: "t2_5", albumId: "alb_2", title: "heart pt. 6", trackNumber: 5, durationMs: 310_000, spotifyId: nil),
            Track(id: "t2_6", albumId: "alb_2", title: "gnx", trackNumber: 6, durationMs: 198_000, spotifyId: nil),
            Track(id: "t2_7", albumId: "alb_2", title: "hey now", trackNumber: 7, durationMs: 224_000, spotifyId: nil),
            Track(id: "t2_8", albumId: "alb_2", title: "reincarnated", trackNumber: 8, durationMs: 285_000, spotifyId: nil),
            Track(id: "t2_9", albumId: "alb_2", title: "man at the garden", trackNumber: 9, durationMs: 243_000, spotifyId: nil),
            Track(id: "t2_10", albumId: "alb_2", title: "dodger blue", trackNumber: 10, durationMs: 206_000, spotifyId: nil),
            Track(id: "t2_11", albumId: "alb_2", title: "peaches", trackNumber: 11, durationMs: 231_000, spotifyId: nil),
            Track(id: "t2_12", albumId: "alb_2", title: "gloria", trackNumber: 12, durationMs: 267_000, spotifyId: nil),
        ],
        "alb_3": [
            Track(id: "t3_1", albumId: "alb_3", title: "Taste", trackNumber: 1, durationMs: 177_000, spotifyId: nil),
            Track(id: "t3_2", albumId: "alb_3", title: "Please Please Please", trackNumber: 2, durationMs: 186_000, spotifyId: nil),
            Track(id: "t3_3", albumId: "alb_3", title: "Good Luck, Babe!", trackNumber: 3, durationMs: 218_000, spotifyId: nil),
            Track(id: "t3_4", albumId: "alb_3", title: "Sharpest Tool", trackNumber: 4, durationMs: 195_000, spotifyId: nil),
            Track(id: "t3_5", albumId: "alb_3", title: "Coincidence", trackNumber: 5, durationMs: 169_000, spotifyId: nil),
            Track(id: "t3_6", albumId: "alb_3", title: "Bed Chem", trackNumber: 6, durationMs: 201_000, spotifyId: nil),
            Track(id: "t3_7", albumId: "alb_3", title: "Espresso", trackNumber: 7, durationMs: 175_000, spotifyId: nil),
            Track(id: "t3_8", albumId: "alb_3", title: "Dumb & Poetic", trackNumber: 8, durationMs: 183_000, spotifyId: nil),
            Track(id: "t3_9", albumId: "alb_3", title: "Slim Pickins", trackNumber: 9, durationMs: 164_000, spotifyId: nil),
            Track(id: "t3_10", albumId: "alb_3", title: "Juno", trackNumber: 10, durationMs: 191_000, spotifyId: nil),
            Track(id: "t3_11", albumId: "alb_3", title: "Lie to Girls", trackNumber: 11, durationMs: 198_000, spotifyId: nil),
            Track(id: "t3_12", albumId: "alb_3", title: "Don't Smile", trackNumber: 12, durationMs: 212_000, spotifyId: nil),
        ],
        "alb_4": [
            Track(id: "t4_1", albumId: "alb_4", title: "360", trackNumber: 1, durationMs: 134_000, spotifyId: nil),
            Track(id: "t4_2", albumId: "alb_4", title: "Club classics", trackNumber: 2, durationMs: 174_000, spotifyId: nil),
            Track(id: "t4_3", albumId: "alb_4", title: "Sympathy is a knife", trackNumber: 3, durationMs: 195_000, spotifyId: nil),
            Track(id: "t4_4", albumId: "alb_4", title: "I might say something stupid", trackNumber: 4, durationMs: 185_000, spotifyId: nil),
            Track(id: "t4_5", albumId: "alb_4", title: "Talk talk", trackNumber: 5, durationMs: 203_000, spotifyId: nil),
            Track(id: "t4_6", albumId: "alb_4", title: "Von dutch", trackNumber: 6, durationMs: 147_000, spotifyId: nil),
            Track(id: "t4_7", albumId: "alb_4", title: "Everything is romantic", trackNumber: 7, durationMs: 241_000, spotifyId: nil),
            Track(id: "t4_8", albumId: "alb_4", title: "Rewind", trackNumber: 8, durationMs: 177_000, spotifyId: nil),
            Track(id: "t4_9", albumId: "alb_4", title: "So I", trackNumber: 9, durationMs: 213_000, spotifyId: nil),
            Track(id: "t4_10", albumId: "alb_4", title: "Girl, so confusing", trackNumber: 10, durationMs: 198_000, spotifyId: nil),
            Track(id: "t4_11", albumId: "alb_4", title: "Apple", trackNumber: 11, durationMs: 224_000, spotifyId: nil),
            Track(id: "t4_12", albumId: "alb_4", title: "B2b", trackNumber: 12, durationMs: 166_000, spotifyId: nil),
            Track(id: "t4_13", albumId: "alb_4", title: "Mean girls", trackNumber: 13, durationMs: 209_000, spotifyId: nil),
            Track(id: "t4_14", albumId: "alb_4", title: "I think about it all the time", trackNumber: 14, durationMs: 183_000, spotifyId: nil),
            Track(id: "t4_15", albumId: "alb_4", title: "365", trackNumber: 15, durationMs: 251_000, spotifyId: nil),
        ],
        "alb_7": [
            Track(id: "t7_1", albumId: "alb_7", title: "SKINNY", trackNumber: 1, durationMs: 219_000, spotifyId: nil),
            Track(id: "t7_2", albumId: "alb_7", title: "LUNCH", trackNumber: 2, durationMs: 179_000, spotifyId: nil),
            Track(id: "t7_3", albumId: "alb_7", title: "CHIHIRO", trackNumber: 3, durationMs: 303_000, spotifyId: nil),
            Track(id: "t7_4", albumId: "alb_7", title: "BIRDS OF A FEATHER", trackNumber: 4, durationMs: 210_000, spotifyId: nil),
            Track(id: "t7_5", albumId: "alb_7", title: "WILDFLOWER", trackNumber: 5, durationMs: 261_000, spotifyId: nil),
            Track(id: "t7_6", albumId: "alb_7", title: "THE GREATEST", trackNumber: 6, durationMs: 294_000, spotifyId: nil),
            Track(id: "t7_7", albumId: "alb_7", title: "L'AMOUR DE MA VIE", trackNumber: 7, durationMs: 333_000, spotifyId: nil),
            Track(id: "t7_8", albumId: "alb_7", title: "THE DINER", trackNumber: 8, durationMs: 185_000, spotifyId: nil),
            Track(id: "t7_9", albumId: "alb_7", title: "BITTERSUITE", trackNumber: 9, durationMs: 298_000, spotifyId: nil),
            Track(id: "t7_10", albumId: "alb_7", title: "BLUE", trackNumber: 10, durationMs: 342_000, spotifyId: nil),
        ],
        "alb_9": [
            Track(id: "t9_1", albumId: "alb_9", title: "AMERIICAN REQUIEM", trackNumber: 1, durationMs: 267_000, spotifyId: nil),
            Track(id: "t9_2", albumId: "alb_9", title: "BLACKBIIRD", trackNumber: 2, durationMs: 231_000, spotifyId: nil),
            Track(id: "t9_3", albumId: "alb_9", title: "16 CARRIAGES", trackNumber: 3, durationMs: 219_000, spotifyId: nil),
            Track(id: "t9_4", albumId: "alb_9", title: "PROTECTOR", trackNumber: 4, durationMs: 196_000, spotifyId: nil),
            Track(id: "t9_5", albumId: "alb_9", title: "MY ROSE", trackNumber: 5, durationMs: 244_000, spotifyId: nil),
            Track(id: "t9_6", albumId: "alb_9", title: "SMOKE HOUR", trackNumber: 6, durationMs: 210_000, spotifyId: nil),
            Track(id: "t9_7", albumId: "alb_9", title: "TEXAS HOLD 'EM", trackNumber: 7, durationMs: 237_000, spotifyId: nil),
            Track(id: "t9_8", albumId: "alb_9", title: "BODYGUARD", trackNumber: 8, durationMs: 193_000, spotifyId: nil),
        ],
    ]

    static let defaultNotificationPreferences = NotificationPreferences()

    static let initialRecap = WeeklyRecap(
        id: "rcp_local", weekStart: "2026-03-03", weekEnd: "2026-03-10",
        totalLogs: 12, averageRating: 4.1,
        shareText: "My SoundScore week: 12 logs, avg 4.1★",
        deepLink: "https://soundscore.app/recaps/weekly/2026-03-03"
    )
}
