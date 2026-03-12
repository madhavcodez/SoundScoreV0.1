package com.soundscore.app.ui.navigation

data class DeepLinkDestination(
    val screen: Screen,
    val message: String,
)

object DeepLinkResolver {
    fun resolve(uri: String): DeepLinkDestination {
        return when {
            uri.contains("/lists/") -> DeepLinkDestination(Screen.Lists, "Opened from shared list link")
            uri.contains("/recaps/") -> DeepLinkDestination(Screen.Profile, "Opened from recap link")
            uri.contains("/u/") -> DeepLinkDestination(Screen.Profile, "Opened from profile link")
            uri.contains("/album/") -> DeepLinkDestination(Screen.Search, "Opened from album link")
            else -> DeepLinkDestination(Screen.Feed, "Opened from external link")
        }
    }
}
