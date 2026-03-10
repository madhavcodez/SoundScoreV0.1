package com.soundscore.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.soundscore.app.ui.components.AlbumArtPlaceholder
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.theme.*
import com.soundscore.app.ui.viewmodel.SearchViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun SearchScreen(
    modifier: Modifier = Modifier,
    searchViewModel: SearchViewModel = viewModel(),
) {
    val uiState by searchViewModel.uiState.collectAsStateWithLifecycle()

    Column(modifier = modifier.fillMaxSize()) {
        // ── Header ──
        Text(
            "Search",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(horizontal = 18.dp, vertical = 8.dp),
        )

        // ── Search bar ──
        OutlinedTextField(
            value = uiState.query,
            onValueChange = { searchViewModel.updateQuery(it) },
            placeholder = {
                Text("Albums, artists, friends…", color = ChromeFaint)
            },
            leadingIcon = {
                Icon(Icons.Default.Search, contentDescription = null, tint = ChromeDim)
            },
            singleLine = true,
            shape = RoundedCornerShape(14.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = GlassBg,
                unfocusedContainerColor = GlassBg,
                focusedBorderColor = ElectricBlue,
                unfocusedBorderColor = GlassBorder,
                cursorColor = ElectricBlue,
                focusedTextColor = TextPrimary,
                unfocusedTextColor = TextPrimary,
            ),
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 4.dp),
        )

        Spacer(Modifier.height(12.dp))

        // ── Results / browse ──
        Text(
            if (uiState.query.isBlank()) "TRENDING" else "RESULTS",
            style = MaterialTheme.typography.labelMedium,
            color = TextTertiary,
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 4.dp),
        )

        LazyColumn(
            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            items(uiState.results, key = { it.id }) { album ->
                GlassCard(cornerRadius = 12.dp) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        AlbumArtPlaceholder(
                            colors = album.artColors,
                            modifier = Modifier.size(44.dp),
                            cornerRadius = 8.dp,
                        )
                        Spacer(Modifier.width(10.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(album.title, style = MaterialTheme.typography.titleSmall)
                            Text(
                                "${album.artist} · ${album.year}",
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary,
                            )
                        }
                        Text(
                            "${album.avgRating}",
                            style = MaterialTheme.typography.titleSmall,
                            color = ElectricBlue,
                        )
                    }
                }
            }
        }
    }
}
