package com.soundscore.app

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.soundscore.app.ui.components.AppBackdrop
import com.soundscore.app.ui.navigation.DeepLinkResolver
import com.soundscore.app.ui.navigation.Screen
import com.soundscore.app.ui.screens.FeedScreen
import com.soundscore.app.ui.screens.ListsScreen
import com.soundscore.app.ui.screens.LogScreen
import com.soundscore.app.ui.screens.ProfileScreen
import com.soundscore.app.ui.screens.SearchScreen
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.AccentGreenDim
import com.soundscore.app.ui.theme.ChromeDim
import com.soundscore.app.ui.theme.DarkBase
import com.soundscore.app.ui.theme.GlassBorder
import com.soundscore.app.ui.theme.GlassFrosted

@Composable
fun SoundScoreApp(startDeepLink: String? = null) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val snackbarHostState = remember { SnackbarHostState() }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBase)
    ) {
        AppBackdrop()
        Scaffold(
            containerColor = Color.Transparent,
            snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
            bottomBar = {
                FloatingNavigationBar(
                    screens = Screen.all,
                    currentDestination = currentDestination,
                    onNavigate = { screen ->
                        navController.navigate(screen) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                )
            }
        ) { innerPadding ->
            LaunchedEffect(startDeepLink) {
                val deepLink = startDeepLink ?: return@LaunchedEffect
                val destination = DeepLinkResolver.resolve(deepLink)
                navController.navigate(destination.screen) {
                    launchSingleTop = true
                }
                snackbarHostState.showSnackbar(destination.message)
            }

            NavHost(
                navController = navController,
                startDestination = Screen.Feed,
                modifier = Modifier.fillMaxSize(),
                enterTransition = {
                    fadeIn(animationSpec = tween(350)) + slideInVertically(
                        initialOffsetY = { 20 },
                        animationSpec = spring(dampingRatio = 0.85f, stiffness = 350f)
                    )
                },
                exitTransition = { fadeOut(animationSpec = tween(250)) },
                popEnterTransition = {
                    fadeIn(animationSpec = tween(350)) + slideInVertically(
                        initialOffsetY = { -20 },
                        animationSpec = spring(dampingRatio = 0.85f, stiffness = 350f)
                    )
                },
                popExitTransition = { fadeOut(animationSpec = tween(250)) }
            ) {
                composable<Screen.Feed> {
                    Box(Modifier.padding(innerPadding)) { FeedScreen() }
                }
                composable<Screen.Log> {
                    Box(Modifier.padding(innerPadding)) { LogScreen() }
                }
                composable<Screen.Search> {
                    Box(Modifier.padding(innerPadding)) { SearchScreen() }
                }
                composable<Screen.Lists> {
                    Box(Modifier.padding(innerPadding)) { ListsScreen() }
                }
                composable<Screen.Profile> {
                    Box(Modifier.padding(innerPadding)) { ProfileScreen() }
                }
            }
        }
    }
}

@Composable
fun FloatingNavigationBar(
    screens: List<Screen>,
    currentDestination: NavDestination?,
    onNavigate: (Screen) -> Unit,
) {
    val haptic = LocalHapticFeedback.current
    val shape = RoundedCornerShape(28.dp)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .padding(horizontal = 24.dp)
            .padding(bottom = 12.dp),
        contentAlignment = Alignment.BottomCenter,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp)
                .clip(shape)
                .background(
                    Brush.verticalGradient(
                        listOf(GlassFrosted, GlassFrosted.copy(alpha = 0.22f))
                    )
                )
                .border(0.5.dp, GlassBorder, shape)
                .padding(horizontal = 8.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxSize(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                screens.forEach { screen ->
                    val selected = currentDestination?.hierarchy?.any {
                        it.hasRoute(screen::class)
                    } == true

                    val iconAlpha by animateFloatAsState(
                        targetValue = if (selected) 1f else 0.45f,
                        animationSpec = tween(250),
                        label = "iconAlpha"
                    )

                    val iconSize by animateDpAsState(
                        targetValue = if (selected) 26.dp else 22.dp,
                        animationSpec = spring(dampingRatio = 0.6f, stiffness = 500f),
                        label = "iconSize"
                    )

                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight(),
                    ) {
                        IconButton(
                            onClick = {
                                if (!selected) {
                                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                }
                                onNavigate(screen)
                            }
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(4.dp),
                            ) {
                                Icon(
                                    imageVector = if (selected) screen.iconFilled else screen.iconOutlined,
                                    contentDescription = screen.label,
                                    tint = (if (selected) AccentGreen else Color.White).copy(alpha = iconAlpha),
                                    modifier = Modifier.size(iconSize),
                                )
                                Box(
                                    modifier = Modifier
                                        .size(4.dp)
                                        .clip(CircleShape)
                                        .graphicsLayer {
                                            alpha = if (selected) 1f else 0f
                                        }
                                        .background(AccentGreen),
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
