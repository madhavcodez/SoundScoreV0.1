package com.soundscore.app.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.ui.graphics.vector.ImageVector
import kotlinx.serialization.Serializable

sealed interface Screen {
    val label: String
    val iconFilled: ImageVector
    val iconOutlined: ImageVector

    @Serializable data object Feed : Screen {
        override val label = "Feed"
        override val iconFilled = Icons.Filled.Home
        override val iconOutlined = Icons.Outlined.Home
    }

    @Serializable data object Log : Screen {
        override val label = "Log"
        override val iconFilled = Icons.Filled.AddCircle
        override val iconOutlined = Icons.Outlined.AddCircleOutline
    }

    @Serializable data object Search : Screen {
        override val label = "Search"
        override val iconFilled = Icons.Filled.Search
        override val iconOutlined = Icons.Outlined.Search
    }

    @Serializable data object Lists : Screen {
        override val label = "Lists"
        override val iconFilled = Icons.AutoMirrored.Filled.List
        override val iconOutlined = Icons.AutoMirrored.Outlined.List
    }

    @Serializable data object Profile : Screen {
        override val label = "Profile"
        override val iconFilled = Icons.Filled.Person
        override val iconOutlined = Icons.Outlined.Person
    }

    companion object {
        val all = listOf(Feed, Log, Search, Lists, Profile)
    }
}
