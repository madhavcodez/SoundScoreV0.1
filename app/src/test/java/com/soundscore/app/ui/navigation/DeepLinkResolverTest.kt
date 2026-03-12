package com.soundscore.app.ui.navigation

import org.junit.Assert.assertEquals
import org.junit.Test

class DeepLinkResolverTest {
    @Test
    fun resolvesListLinkToListsScreen() {
        val result = DeepLinkResolver.resolve("https://soundscore.app/lists/123")
        assertEquals(Screen.Lists, result.screen)
    }

    @Test
    fun resolvesAlbumLinkToSearchScreen() {
        val result = DeepLinkResolver.resolve("https://soundscore.app/album/alb_1")
        assertEquals(Screen.Search, result.screen)
    }
}
