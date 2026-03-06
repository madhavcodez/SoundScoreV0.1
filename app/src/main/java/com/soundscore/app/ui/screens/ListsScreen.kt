package com.soundscore.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.soundscore.app.ui.components.BlueButton
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.theme.*

@Composable
fun ListsScreen(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxSize(),
    ) {
        // ── Header ──
        Text(
            "Lists",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(horizontal = 18.dp, vertical = 8.dp),
        )

        // ── Empty state — ready for feature build-out ──
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            GlassCard(cornerRadius = 20.dp) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 24.dp),
                ) {
                    Text(
                        "Curate your taste",
                        style = MaterialTheme.typography.titleLarge,
                        color = ChromeLight,
                    )
                    Spacer(Modifier.height(6.dp))
                    Text(
                        "Create ranked lists, share them\nas cards, discover what friends list.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = TextSecondary,
                        modifier = Modifier.padding(horizontal = 16.dp),
                    )
                    Spacer(Modifier.height(18.dp))
                    BlueButton(text = "Create your first list", onClick = { /* TODO */ })
                }
            }
        }
    }
}
