package com.soundscore.app.data.model

import androidx.compose.ui.graphics.Color
import com.soundscore.app.ui.theme.AlbumColors

data class Album(
    val id: String,
    val title: String,
    val artist: String,
    val year: Int,
    val artColors: List<Color>,
    val artworkUrl: String? = null,
    val avgRating: Float = 0f,
    val logCount: Int = 0,
)

data class FeedItem(
    val id: String,
    val username: String,
    val action: String,
    val album: Album,
    val rating: Float,
    val reviewSnippet: String? = null,
    val likes: Int = 0,
    val comments: Int = 0,
    val timeAgo: String = "",
    val isLiked: Boolean = false,
)

data class UserProfile(
    val handle: String,
    val bio: String,
    val logCount: Int,
    val reviewCount: Int,
    val listCount: Int,
    val topAlbums: List<Pair<Album, Float>>,
    val genres: List<String>,
    val avgRating: Float,
    val albumsCount: Int = logCount,
    val followingCount: Int = 0,
    val followersCount: Int = 0,
    val favoriteAlbums: List<Album> = topAlbums.map { it.first },
)

data class UserList(
    val id: String,
    val title: String,
    val note: String? = null,
    val albumIds: List<String> = emptyList(),
    val curatorHandle: String = "@madhav",
    val saves: Int = 0,
)

data class NotificationPreferences(
    val socialEnabled: Boolean = true,
    val recapEnabled: Boolean = true,
    val commentEnabled: Boolean = true,
    val reactionEnabled: Boolean = true,
    val quietHoursStart: Int = 22,
    val quietHoursEnd: Int = 7,
)

data class WeeklyRecap(
    val id: String,
    val weekStart: String,
    val weekEnd: String,
    val totalLogs: Int,
    val averageRating: Float,
    val shareText: String,
    val deepLink: String,
)

object SeedData {
    private fun hiResArtwork(url: String) = url
        .replace("100x100bb.jpg", "600x600bb.jpg")
        .replace("100x100bb.png", "600x600bb.png")

    val albums = listOf(
        Album(
            id = "alb_1",
            title = "CHROMAKOPIA",
            artist = "Tyler, the Creator",
            year = 2024,
            artColors = AlbumColors.forest,
            artworkUrl = hiResArtwork("https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/b6/ef/ee/b6efeefa-fc99-37d1-ad21-0d769b2a4958/196872796971.jpg/100x100bb.jpg"),
            avgRating = 4.3f,
            logCount = 2100,
        ),
        Album(
            id = "alb_2",
            title = "GNX",
            artist = "Kendrick Lamar",
            year = 2024,
            artColors = AlbumColors.midnight,
            artworkUrl = hiResArtwork("https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/54/28/14/54281424-eece-0935-299d-fdd2ab403f92/24UM1IM28978.rgb.jpg/100x100bb.jpg"),
            avgRating = 4.1f,
            logCount = 1800,
        ),
        Album(
            id = "alb_3",
            title = "Short n' Sweet",
            artist = "Sabrina Carpenter",
            year = 2024,
            artColors = AlbumColors.lime,
            artworkUrl = hiResArtwork("https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/a1/1c/ca/a11ccab6-7d4c-e041-d028-998bcebeb709/24UMGIM61704.rgb.jpg/100x100bb.jpg"),
            avgRating = 3.8f,
            logCount = 950,
        ),
        Album(
            id = "alb_4",
            title = "Brat",
            artist = "Charli XCX",
            year = 2024,
            artColors = AlbumColors.rose,
            artworkUrl = null,
            avgRating = 4.0f,
            logCount = 3200,
        ),
        Album(
            id = "alb_5",
            title = "Manning Fireside",
            artist = "Mk.gee",
            year = 2024,
            artColors = AlbumColors.lagoon,
            artworkUrl = null,
            avgRating = 3.9f,
            logCount = 620,
        ),
        Album(
            id = "alb_6",
            title = "The Great Impersonator",
            artist = "Halsey",
            year = 2024,
            artColors = AlbumColors.ember,
            artworkUrl = null,
            avgRating = 3.5f,
            logCount = 430,
        ),
    )

    val feedItems = listOf(
        FeedItem(
            id = "f1",
            username = "rohan",
            action = "logged a perfect score",
            album = albums[0],
            rating = 5.0f,
            reviewSnippet = "Tyler made a world, not just a tracklist.",
            likes = 12,
            comments = 3,
            timeAgo = "2h",
            isLiked = true,
        ),
        FeedItem(
            id = "f2",
            username = "priya",
            action = "left a glowing review",
            album = albums[2],
            rating = 4.0f,
            reviewSnippet = "Hooks for days, but the production is what sticks.",
            likes = 8,
            comments = 1,
            timeAgo = "5h",
        ),
        FeedItem(
            id = "f3",
            username = "kai",
            action = "added this to a late-night list",
            album = albums[3],
            rating = 4.5f,
            reviewSnippet = "The whole thing feels fluorescent and slightly dangerous.",
            likes = 24,
            comments = 7,
            timeAgo = "8h",
        ),
    )

    val logInitialRatings = mapOf(
        "alb_1" to 5f,
        "alb_2" to 4.5f,
        "alb_3" to 4f,
        "alb_4" to 4.5f,
    )

    val myProfile = UserProfile(
        handle = "@madhav",
        bio = "Taste journal for records worth replaying at 1 a.m.",
        logCount = 142,
        reviewCount = 38,
        listCount = 24,
        topAlbums = listOf(
            albums[0] to 5.0f,
            albums[2] to 4.5f,
            albums[3] to 4.5f,
            albums[4] to 4.0f,
            albums[5] to 4.0f,
            albums[1] to 3.5f,
        ),
        genres = listOf("Indie Sleaze", "Alt Rap", "Digital Pop", "Neo-Soul", "Late Night", "Avg 4.1 ★"),
        avgRating = 4.1f,
        albumsCount = 142,
        followingCount = 186,
        followersCount = 248,
        favoriteAlbums = listOf(
            albums[0],
            albums[3],
            albums[2],
            albums[1],
            albums[4],
            albums[5],
        ),
    )

    val initialLists = listOf(
        UserList(
            id = "l1",
            title = "Albums I Would Defend",
            note = "Chaotic, immediate, impossible to half-love.",
            albumIds = listOf("alb_4", "alb_1", "alb_2", "alb_3"),
            curatorHandle = "@madhav",
            saves = 128,
        ),
        UserList(
            id = "l2",
            title = "Midnight Headphones",
            note = "For the train ride home when the city still feels loud.",
            albumIds = listOf("alb_5", "alb_6", "alb_1", "alb_2"),
            curatorHandle = "@priya",
            saves = 84,
        ),
        UserList(
            id = "l3",
            title = "2024 Pop Mutations",
            note = "Big hooks, weird textures, zero safe choices.",
            albumIds = listOf("alb_3", "alb_4", "alb_2", "alb_1"),
            curatorHandle = "@kai",
            saves = 67,
        ),
    )

    val defaultNotificationPreferences = NotificationPreferences()

    val initialRecap = WeeklyRecap(
        id = "rcp_local",
        weekStart = "2026-03-03",
        weekEnd = "2026-03-10",
        totalLogs = 12,
        averageRating = 4.1f,
        shareText = "My SoundScore week: 12 logs, avg 4.1★",
        deepLink = "https://soundscore.app/recaps/weekly/2026-03-03",
    )
}
