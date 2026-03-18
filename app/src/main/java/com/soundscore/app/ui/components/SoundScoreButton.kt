package com.soundscore.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.DarkBase
import com.soundscore.app.ui.theme.GlassBg
import com.soundscore.app.ui.theme.GlassBorder
import com.soundscore.app.ui.theme.TextPrimary

@Composable
fun BlueButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Button(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = AccentGreen,
            contentColor = DarkBase,
        ),
        contentPadding = PaddingValues(horizontal = 24.dp, vertical = 14.dp),
    ) {
        Text(
            text = text,
            fontWeight = FontWeight.Bold,
            fontSize = 14.sp,
        )
    }
}

@Composable
fun GhostButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        border = BorderStroke(0.5.dp, GlassBorder),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = GlassBg.copy(alpha = 0.6f),
            contentColor = TextPrimary,
        ),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 12.dp),
    ) {
        Text(
            text = text,
            fontWeight = FontWeight.Medium,
            fontSize = 13.sp,
        )
    }
}
