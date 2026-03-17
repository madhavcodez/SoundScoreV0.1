package com.soundscore.app.ui.viewmodel

import com.soundscore.app.data.model.Album
import com.soundscore.app.data.model.UserList
import com.soundscore.app.data.model.UserProfile
import com.soundscore.app.ui.theme.AlbumColors

data class LogSummaryStat(
    val value: String,
    val label: String,
    val caption: String,
)

data class RecentLogEntry(
    val album: Album,
    val rating: Float,
    val dateLabel: String,
    val timeLabel: String,
    val caption: String,
)

data class BrowseGenre(
    val name: String,
    val caption: String,
    val colors: List<androidx.compose.ui.graphics.Color>,
)

data class ChartEntry(
    val rank: Int,
    val album: Album,
    val movementLabel: String,
)

data class ListShowcase(
    val list: UserList,
    val coverAlbums: List<Album>,
)

data class ProfileMetric(
    val value: String,
    val label: String,
)

fun buildTrendingAlbums(albums: List<Album>): List<Album> =
    albums.sortedByDescending { it.logCount }

fun buildLogSummaryStats(ratings: Map<String, Float>): List<LogSummaryStat> {
    val average = if (ratings.isEmpty()) 0f else ratings.values.average().toFloat()
    val weekLogs = ratings.count()
    val streak = (ratings.count() + 2).coerceAtMost(9)

    return listOf(
        LogSummaryStat(value = weekLogs.toString(), label = "This week", caption = "New logs"),
        LogSummaryStat(value = String.format("%.1f★", average), label = "Average", caption = "Your current pace"),
        LogSummaryStat(value = "$streak d", label = "Streak", caption = "Listening every day"),
    )
}

fun buildRecentLogs(albums: List<Album>, ratings: Map<String, Float>): List<RecentLogEntry> {
    val moments = listOf(
        Triple("Today", "11:48 PM", "Late-night replay. Worth the full write-up."),
        Triple("Yesterday", "7:12 PM", "Instant favorite chorus. Logged before dinner."),
        Triple("Mar 11", "9:03 AM", "Sharp production details on the second listen."),
        Triple("Mar 09", "6:41 PM", "Saved for the weekend drive and it landed."),
    )

    return albums
        .sortedByDescending { ratings[it.id] ?: 0f }
        .take(moments.size)
        .mapIndexed { index, album ->
            val (date, time, caption) = moments[index]
            RecentLogEntry(
                album = album,
                rating = ratings[album.id] ?: album.avgRating,
                dateLabel = date,
                timeLabel = time,
                caption = caption,
            )
        }
}

fun buildBrowseGenres(): List<BrowseGenre> = listOf(
    BrowseGenre("Alt Rap", "Dense bars, stranger palettes", AlbumColors.forest),
    BrowseGenre("Night Pop", "Glossy hooks with a bite", AlbumColors.rose),
    BrowseGenre("Leftfield R&B", "Warm low end, sharp edges", AlbumColors.lagoon),
    BrowseGenre("Indie Mutations", "Guitars that still feel digital", AlbumColors.orchid),
)

fun resolveSearchResults(
    query: String,
    albums: List<Album>,
    searchAlbums: (String) -> List<Album>,
): List<Album> = if (query.isBlank()) albums else searchAlbums(query)

fun buildChartEntries(albums: List<Album>): List<ChartEntry> {
    val movementLabels = listOf("+18%", "+12%", "+9%", "+6%", "+4%")
    return albums
        .sortedByDescending { it.logCount }
        .take(movementLabels.size)
        .mapIndexed { index, album ->
            ChartEntry(rank = index + 1, album = album, movementLabel = movementLabels[index])
        }
}

fun resolveListShowcases(lists: List<UserList>, albums: List<Album>): List<ListShowcase> =
    lists.map { list ->
        val coverAlbums = list.albumIds.mapNotNull { id -> albums.find { it.id == id } }.take(4)
        ListShowcase(list = list, coverAlbums = coverAlbums)
    }

fun buildProfileMetrics(profile: UserProfile): List<ProfileMetric> = listOf(
    ProfileMetric(profile.albumsCount.toString(), "Albums"),
    ProfileMetric(profile.listCount.toString(), "Lists"),
    ProfileMetric(profile.followingCount.toString(), "Following"),
    ProfileMetric(profile.followersCount.toString(), "Followers"),
)

fun buildFavoriteAlbums(profile: UserProfile): List<Album> = profile.favoriteAlbums.take(6)
