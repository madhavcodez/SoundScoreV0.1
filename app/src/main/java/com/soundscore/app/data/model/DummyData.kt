package com.soundscore.app.data.model

import androidx.compose.ui.graphics.Color
import com.soundscore.app.ui.theme.AlbumColors

/**
 * Lightweight data classes + static dummy data.
 * Replace with real Room / network models later.
 */

data class Album(
    val id: String,
    val title: String,
    val artist: String,
    val year: Int,
    val artColors: List<Color>,   // gradient placeholder — swap for image URL later
    val avgRating: Float = 0f,
    val logCount: Int = 0,
)

data class FeedItem(
    val id: String,
    val username: String,
    val action: String,           // "logged an album", "rated", "added to list"
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
    val topAlbums: List<Pair<Album, Float>>,   // album + user rating
    val genres: List<String>,
    val avgRating: Float,
)

data class UserList(
    val id: String,
    val title: String,
    val note: String? = null,
    val albumIds: List<String> = emptyList(),
)


// ── Static seed data ──────────────────────────────────────────

object SeedData {

    val albums = listOf(
        Album("1", "CHROMAKOPIA", "Tyler, the Creator", 2024, AlbumColors.purple, 4.3f, 2100),
        Album("2", "GNX", "Kendrick Lamar", 2024, AlbumColors.indigo, 4.1f, 1800),
        Album("3", "Short n' Sweet", "Sabrina Carpenter", 2024, AlbumColors.teal, 3.8f, 950),
        Album("4", "Brat", "Charli XCX", 2024, AlbumColors.pink, 4.0f, 3200),
        Album("5", "Manning Fireside", "Mk.gee", 2024, AlbumColors.blue, 3.9f, 620),
        Album("6", "The Great Impersonator", "Halsey", 2024, AlbumColors.gold, 3.5f, 430),
    )

    val feedItems = listOf(
        FeedItem(
            id = "f1",
            username = "rohan",
            action = "logged an album",
            album = albums[0],
            rating = 5.0f,
            reviewSnippet = "Tyler peaked. Every track is a statement.",
            likes = 12, comments = 3, timeAgo = "2h",
            isLiked = true,
        ),
        FeedItem(
            id = "f2",
            username = "priya",
            action = "rated",
            album = albums[2],
            rating = 4.0f,
            likes = 8, comments = 1, timeAgo = "5h",
        ),
        FeedItem(
            id = "f3",
            username = "kai",
            action = "added to list",
            album = albums[3],
            rating = 4.0f,
            likes = 24, comments = 7, timeAgo = "8h",
        ),
    )

    // Initial ratings for the Log screen (matches mockup visual state)
    val logInitialRatings = mapOf("1" to 5f, "2" to 4f, "3" to 3f)

    val myProfile = UserProfile(
        handle = "@madhav",
        bio = "Taste Journal · music nerd",
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
        genres = listOf("Indie", "Rap", "Electronic", "Alt R&B", "2010s", "Avg 3.9 ★"),
        avgRating = 3.9f,
    )

    val initialLists = listOf(
        UserList(
            id = "l1",
            title = "Albums I Would Defend",
            note = "All gas, no skips.",
            albumIds = listOf("1", "4"),
        ),
    )
}
