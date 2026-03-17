package com.soundscore.app.ui.viewmodel

import com.soundscore.app.data.model.SeedData
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class ScreenPresentationTest {
    @Test
    fun resolveSearchResultsReturnsAllAlbumsWhenQueryBlank() {
        val albums = SeedData.albums

        val results = resolveSearchResults("", albums) { emptyList() }

        assertSame(albums, results)
    }

    @Test
    fun resolveSearchResultsDelegatesToSearchWhenQueryPresent() {
        val albums = SeedData.albums
        var delegatedQuery: String? = null

        val results = resolveSearchResults("Tyler", albums) { query ->
            delegatedQuery = query
            albums.take(1)
        }

        assertEquals("Tyler", delegatedQuery)
        assertEquals(1, results.size)
    }

    @Test
    fun resolveListShowcasesBuildsFourAlbumMosaics() {
        val showcases = resolveListShowcases(SeedData.initialLists, SeedData.albums)

        assertEquals(SeedData.initialLists.size, showcases.size)
        assertEquals(4, showcases.first().coverAlbums.size)
        assertEquals("alb_4", showcases.first().coverAlbums.first().id)
    }

    @Test
    fun buildProfileMetricsUsesAlbumsListsFollowingAndFollowers() {
        val metrics = buildProfileMetrics(SeedData.myProfile)
        val favorites = buildFavoriteAlbums(SeedData.myProfile)

        assertEquals(listOf("Albums", "Lists", "Following", "Followers"), metrics.map { it.label })
        assertEquals(6, favorites.size)
        assertEquals(SeedData.myProfile.favoriteAlbums.first(), favorites.first())
        assertTrue(metrics.any { it.value == SeedData.myProfile.followersCount.toString() })
    }
}
