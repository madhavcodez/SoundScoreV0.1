package com.soundscore.app.ui.screens

import androidx.compose.ui.test.assertExists
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.soundscore.app.data.model.SeedData
import com.soundscore.app.ui.theme.SoundScoreTheme
import com.soundscore.app.ui.viewmodel.FeedUiState
import com.soundscore.app.ui.viewmodel.ListsUiState
import com.soundscore.app.ui.viewmodel.LogUiState
import com.soundscore.app.ui.viewmodel.ProfileUiState
import com.soundscore.app.ui.viewmodel.SearchUiState
import com.soundscore.app.ui.viewmodel.buildBrowseGenres
import com.soundscore.app.ui.viewmodel.buildChartEntries
import com.soundscore.app.ui.viewmodel.buildFavoriteAlbums
import com.soundscore.app.ui.viewmodel.buildLogSummaryStats
import com.soundscore.app.ui.viewmodel.buildProfileMetrics
import com.soundscore.app.ui.viewmodel.buildRecentLogs
import com.soundscore.app.ui.viewmodel.buildTrendingAlbums
import com.soundscore.app.ui.viewmodel.resolveListShowcases
import org.junit.Rule
import org.junit.Test

class ScreenSmokeTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun feedScreenRendersTrendingAndFriendSections() {
        composeTestRule.setContent {
            SoundScoreTheme {
                FeedScreenContent(
                    uiState = FeedUiState(
                        items = SeedData.feedItems,
                        trendingAlbums = buildTrendingAlbums(SeedData.albums),
                    ),
                    onToggleLike = {},
                )
            }
        }

        composeTestRule.onNodeWithText("Albums everyone is circling back to").assertExists()
        composeTestRule.onNodeWithText("Reviews worth opening").assertExists()
    }

    @Test
    fun logScreenRendersStatsAndQuickLogGrid() {
        composeTestRule.setContent {
            SoundScoreTheme {
                LogScreenContent(
                    uiState = LogUiState(
                        quickLogAlbums = buildTrendingAlbums(SeedData.albums).take(6),
                        ratings = SeedData.logInitialRatings,
                        summaryStats = buildLogSummaryStats(SeedData.logInitialRatings),
                        recentLogs = buildRecentLogs(SeedData.albums, SeedData.logInitialRatings),
                    ),
                    onRate = { _, _ -> },
                )
            }
        }

        composeTestRule.onNodeWithText("What you played lately").assertExists()
        composeTestRule.onNodeWithText("Tap covers to keep the habit alive").assertExists()
    }

    @Test
    fun searchScreenSwapsBetweenBrowseAndResults() {
        composeTestRule.setContent {
            SoundScoreTheme {
                SearchScreenContent(
                    uiState = SearchUiState(
                        query = "",
                        results = SeedData.albums,
                        browseGenres = buildBrowseGenres(),
                        chartEntries = buildChartEntries(SeedData.albums),
                    ),
                    onQueryChange = {},
                )
            }
        }

        composeTestRule.onNodeWithText("Start from a corner of your taste").assertExists()

        composeTestRule.setContent {
            SoundScoreTheme {
                SearchScreenContent(
                    uiState = SearchUiState(
                        query = "Tyler",
                        results = SeedData.albums.take(1),
                        browseGenres = buildBrowseGenres(),
                        chartEntries = buildChartEntries(SeedData.albums),
                    ),
                    onQueryChange = {},
                )
            }
        }

        composeTestRule.onNodeWithText("1 matches").assertExists()
    }

    @Test
    fun listsScreenRendersCuratedCollections() {
        composeTestRule.setContent {
            SoundScoreTheme {
                ListsScreenContent(
                    uiState = ListsUiState(
                        lists = SeedData.initialLists,
                        showcases = resolveListShowcases(SeedData.initialLists, SeedData.albums),
                    ),
                    onCreateClick = {},
                )
            }
        }

        composeTestRule.onNodeWithText("Collections to open next").assertExists()
        composeTestRule.onNodeWithText("Albums I Would Defend").assertExists()
    }

    @Test
    fun profileScreenRendersFavoritesAndTasteDna() {
        composeTestRule.setContent {
            SoundScoreTheme {
                ProfileScreenContent(
                    uiState = ProfileUiState(
                        profile = SeedData.myProfile,
                        metrics = buildProfileMetrics(SeedData.myProfile),
                        favoriteAlbums = buildFavoriteAlbums(SeedData.myProfile),
                    ),
                )
            }
        }

        composeTestRule.onNodeWithText("The records pinned to your identity").assertExists()
        composeTestRule.onNodeWithText("Genres and instincts that keep repeating").assertExists()
    }
}
