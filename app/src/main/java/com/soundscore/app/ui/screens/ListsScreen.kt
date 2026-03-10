package com.soundscore.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.soundscore.app.data.model.UserList
import com.soundscore.app.ui.components.BlueButton
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.theme.ChromeLight
import com.soundscore.app.ui.theme.TextSecondary
import com.soundscore.app.ui.theme.TextTertiary
import com.soundscore.app.ui.viewmodel.ListsViewModel

@Composable
fun ListsScreen(
    modifier: Modifier = Modifier,
    listsViewModel: ListsViewModel = viewModel(),
) {
    val uiState by listsViewModel.uiState.collectAsStateWithLifecycle()
    var showCreateDialog by remember { mutableStateOf(false) }
    var draftTitle by remember { mutableStateOf("") }

    if (showCreateDialog) {
        AlertDialog(
            onDismissRequest = { showCreateDialog = false },
            title = { Text("Create list") },
            text = {
                TextField(
                    value = draftTitle,
                    onValueChange = { draftTitle = it },
                    placeholder = { Text("Albums I Would Defend") },
                    singleLine = true,
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    listsViewModel.createList(draftTitle)
                    draftTitle = ""
                    showCreateDialog = false
                }) {
                    Text("Create")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    showCreateDialog = false
                    draftTitle = ""
                }) {
                    Text("Cancel")
                }
            },
        )
    }

    Column(
        modifier = modifier.fillMaxSize(),
    ) {
        Text(
            "Lists",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(horizontal = 18.dp, vertical = 8.dp),
        )

        if (uiState.lists.isEmpty()) {
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
                        BlueButton(
                            text = "Create your first list",
                            onClick = { showCreateDialog = true },
                        )
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                item {
                    BlueButton(
                        text = "Create list",
                        onClick = { showCreateDialog = true },
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
                items(uiState.lists, key = { it.id }) { list ->
                    ListCard(list)
                }
            }
        }
    }
}

@Composable
private fun ListCard(list: UserList) {
    GlassCard(cornerRadius = 14.dp) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = list.title,
                style = MaterialTheme.typography.titleMedium,
            )
            if (!list.note.isNullOrBlank()) {
                Spacer(Modifier.height(4.dp))
                Text(
                    text = list.note,
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                )
            }
            Spacer(Modifier.height(6.dp))
            Text(
                text = "${list.albumIds.size} items",
                style = MaterialTheme.typography.labelSmall,
                color = TextTertiary,
            )
        }
    }
}
