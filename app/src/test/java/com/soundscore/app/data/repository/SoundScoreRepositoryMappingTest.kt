package com.soundscore.app.data.repository

import com.soundscore.app.data.api.AlbumDto
import com.soundscore.app.data.model.SeedData
import org.junit.Assert.assertEquals
import org.junit.Test

class SoundScoreRepositoryMappingTest {
    @Test
    fun mapAlbumDtoPreservesArtworkUrl() {
        val dto = AlbumDto(
            id = "alb_1",
            title = "CHROMAKOPIA",
            artist = "Tyler, the Creator",
            year = 2024,
            artworkUrl = "https://example.com/cover.jpg",
            avgRating = 4.6f,
            logCount = 999,
        )

        val mapped = mapAlbumDto(dto, SeedData.albums)

        assertEquals("https://example.com/cover.jpg", mapped.artworkUrl)
        assertEquals(SeedData.albums.first().artColors, mapped.artColors)
    }
}
