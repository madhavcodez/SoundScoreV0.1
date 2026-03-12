package com.soundscore.app

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.soundscore.app.ui.navigation.DeepLinkResolver
import com.soundscore.app.ui.navigation.Screen
import com.soundscore.app.ui.screens.*
import com.soundscore.app.ui.theme.*
import com.soundscore.app.ui.components.GlassCard

@Composable
fun SoundScoreApp(startDeepLink: String? = null) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val snackbarHostState = remember { SnackbarHostState() }

    Box(modifier = Modifier
        .fillMaxSize()
        .background(DarkBase)) {
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
                    fadeIn(animationSpec = tween(400)) + slideInVertically(
                        initialOffsetY = { 30 },
                        animationSpec = spring(dampingRatio = 0.8f, stiffness = 300f)
                    )
                },
                exitTransition = {
                    fadeOut(animationSpec = tween(300))
                },
                popEnterTransition = {
                    fadeIn(animationSpec = tween(400)) + slideInVertically(
                        initialOffsetY = { -30 },
                        animationSpec = spring(dampingRatio = 0.8f, stiffness = 300f)
                    )
                },
                popExitTransition = {
                    fadeOut(animationSpec = tween(300))
                }
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
    currentDestination: androidx.navigation.NavDestination?,
    onNavigate: (Screen) -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(bottom = 28.dp),
        contentAlignment = Alignment.BottomCenter
    ) {
        GlassCard(
            cornerRadius = 35.dp,
            modifier = Modifier.height(76.dp),
            borderColor = Color.White.copy(alpha = 0.12f)
        ) {
            Row(
                modifier = Modifier.fillMaxSize(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                screens.forEach { screen ->
                    val selected = currentDestination?.hierarchy?.any {
                        it.hasRoute(screen::class)
                    } == true

                    val animatedSize by animateDpAsState(
                        targetValue = if (selected) 30.dp else 24.dp,
                        animationSpec = spring(dampingRatio = 0.6f, stiffness = 400f),
                        label = "iconSize"
                    )

                    val animatedAlpha by animateFloatAsState(
                        targetValue = if (selected) 1f else 0.4f,
                        animationSpec = tween(300),
                        label = "iconAlpha"
                    )

                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                    ) {
                        // Subtle selection glow
                        if (selected) {
                            Box(
                                modifier = Modifier
                                    .size(45.dp)
                                    .background(
                                        brush = androidx.compose.ui.graphics.Brush.radialGradient(
                                            listOf(ElectricBlue.copy(alpha = 0.15f), Color.Transparent)
                                        ),
                                        shape = CircleShape
                                    )
                            )
                        }

                        IconButton(
                            onClick = { onNavigate(screen) }
                        ) {
                            Icon(
                                imageVector = if (selected) screen.iconFilled else screen.iconOutlined,
                                contentDescription = screen.label,
                                tint = (if (selected) ElectricBlue else Color.White).copy(alpha = animatedAlpha),
                                modifier = Modifier.size(animatedSize)
                            )
                        }
                    }
                }
            }
        }
    }
}
