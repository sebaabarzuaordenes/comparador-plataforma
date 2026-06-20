package net.squirrelweb.quijote_kotlin

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// Colors
val DarkBg = Color(0xFF1a1a2e)
val DarkCard = Color(0xFF16213e)
val Accent = Color(0xFFe94560)
val AccentGreen = Color(0xFF06d6a0)
val AccentYellow = Color(0xFFffd166)
val AccentBlue = Color(0xFFa8dadc)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme(colorScheme = darkColorScheme()) {
                ProcessingScreen(
                    loadText = {
                        assets.open("quijote.txt").bufferedReader(Charsets.UTF_8).readText()
                    }
                )
            }
        }
    }
}

@Composable
fun ProcessingScreen(loadText: suspend () -> String) {
    val scope = rememberCoroutineScope()
    var result by remember { mutableStateOf<ProcessingResult?>(null) }
    var isProcessing by remember { mutableStateOf(false) }
    var progress by remember { mutableStateOf(0f) }
    var showModal by remember { mutableStateOf(false) }

    val gradient = Brush.verticalGradient(listOf(DarkBg, DarkCard, Color(0xFF0f3460)))

    Box(
        Modifier
            .fillMaxSize()
            .background(gradient)
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(32.dp))

            // Header
            Icon(Icons.Default.Search, null, tint = Accent, modifier = Modifier.size(56.dp))
            Spacer(Modifier.height(8.dp))
            Text("Procesamiento", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color.White)
            Text("Don Quijote de la Mancha", fontSize = 14.sp, color = AccentBlue)

            Spacer(Modifier.height(24.dp))

            // Botón
            Button(
                onClick = {
                    scope.launch {
                        isProcessing = true
                        progress = 0f
                        val text = withContext(Dispatchers.IO) { loadText() }
                        // Simular progreso
                        launch {
                            repeat(90) {
                                kotlinx.coroutines.delay(30)
                                progress = it / 90f
                            }
                        }
                        val r = withContext(Dispatchers.Default) { ProcessingEngine.process(text) }
                        progress = 1f
                        result = r
                        isProcessing = false
                    }
                },
                enabled = !isProcessing,
                colors = ButtonDefaults.buttonColors(containerColor = Accent),
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp)
            ) {
                if (isProcessing) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
                    Spacer(Modifier.width(8.dp))
                    Text("Procesando...", fontWeight = FontWeight.Bold)
                } else {
                    Icon(Icons.Default.PlayArrow, null)
                    Spacer(Modifier.width(8.dp))
                    Text("Procesar Texto", fontWeight = FontWeight.Bold)
                }
            }

            if (isProcessing) {
                Spacer(Modifier.height(12.dp))
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(3.dp)),
                    color = Accent
                )
                Text("Analizando texto...", fontSize = 12.sp, color = AccentBlue)
            }

            AnimatedVisibility(visible = result != null) {
                result?.let { r ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Spacer(Modifier.height(16.dp))

                        // Tiempo
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .background(Color.White.copy(0.08f), RoundedCornerShape(12.dp))
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.Timer, null, tint = Accent)
                            Spacer(Modifier.width(8.dp))
                            Text("Tiempo de procesamiento:", color = Color.White, modifier = Modifier.weight(1f))
                            Text("${r.processingTimeMs} ms", color = AccentBlue, fontWeight = FontWeight.Bold)
                        }

                        Spacer(Modifier.height(16.dp))

                        // Cards stats en grid 2x2
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            StatCard("Palabras", r.wordCount, Icons.Default.TextFields, Accent, Modifier.weight(1f))
                            StatCard("Oraciones", r.sentenceCount, Icons.Default.FormatAlignLeft, AccentGreen, Modifier.weight(1f))
                        }
                        Spacer(Modifier.height(12.dp))
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            StatCard("Párrafos", r.paragraphCount, Icons.Default.Article, AccentYellow, Modifier.weight(1f))
                            StatCard("Palabras únicas", r.wordFrequency.size, Icons.Default.List, AccentBlue, Modifier.weight(1f))
                        }

                        Spacer(Modifier.height(16.dp))

                        // Top 10 gráfico
                        Column(
                            Modifier
                                .fillMaxWidth()
                                .background(Color.White.copy(0.06f), RoundedCornerShape(16.dp))
                                .padding(16.dp)
                        ) {
                            Text("Top 10 Palabras Más Frecuentes", color = Color.White, fontWeight = FontWeight.Bold)
                            Spacer(Modifier.height(12.dp))
                            val top10 = r.wordFrequency.take(10)
                            val maxVal = top10.firstOrNull()?.second ?: 1
                            top10.forEach { (word, count) ->
                                Row(
                                    Modifier.fillMaxWidth().padding(vertical = 3.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(word, color = Color.White, fontSize = 12.sp, modifier = Modifier.width(90.dp))
                                    val anim by animateFloatAsState(count.toFloat() / maxVal)
                                    Box(
                                        Modifier
                                            .weight(1f)
                                            .height(16.dp)
                                            .background(Color.White.copy(0.1f), RoundedCornerShape(8.dp))
                                    ) {
                                        Box(
                                            Modifier
                                                .fillMaxHeight()
                                                .fillMaxWidth(anim)
                                                .background(Accent, RoundedCornerShape(8.dp))
                                        )
                                    }
                                    Spacer(Modifier.width(8.dp))
                                    Text("$count", color = AccentBlue, fontSize = 11.sp, modifier = Modifier.width(40.dp), textAlign = TextAlign.End)
                                }
                            }
                        }

                        Spacer(Modifier.height(12.dp))

                        // Botón modal
                        OutlinedButton(
                            onClick = { showModal = true },
                            modifier = Modifier.fillMaxWidth().height(50.dp),
                            shape = RoundedCornerShape(14.dp),
                            border = BorderStroke(1.dp, AccentBlue.copy(0.5f)),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = AccentBlue)
                        ) {
                            Icon(Icons.Default.List, null)
                            Spacer(Modifier.width(8.dp))
                            Text("Ver Todas las Palabras (${r.wordFrequency.size})", fontWeight = FontWeight.SemiBold)
                        }

                        Spacer(Modifier.height(30.dp))
                    }
                }
            }
        }

        if (showModal) {
            result?.let { r ->
                WordFrequencyModal(r.wordFrequency) { showModal = false }
            }
        }
    }
}

@Composable
fun StatCard(label: String, value: Int, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color, modifier: Modifier = Modifier) {
    Column(
        modifier
            .background(Color.White.copy(0.08f), RoundedCornerShape(14.dp))
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(icon, null, tint = color, modifier = Modifier.size(28.dp))
        Spacer(Modifier.height(6.dp))
        Text(
            value.toString().reversed().chunked(3).joinToString(".").reversed(),
            fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color.White
        )
        Text(label, fontSize = 11.sp, color = Color.White.copy(0.6f))
    }
}

@Composable
fun WordFrequencyModal(wordFrequency: List<Pair<String, Int>>, onDismiss: () -> Unit) {
    var search by remember { mutableStateOf("") }
    val filtered = if (search.isEmpty()) wordFrequency
    else wordFrequency.filter { it.first.contains(search.lowercase()) }
    val maxVal = wordFrequency.firstOrNull()?.second ?: 1

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .background(DarkBg)
        ) {
            Column(Modifier.fillMaxSize()) {
                // Toolbar
                Row(
                    Modifier
                        .fillMaxWidth()
                        .background(Color(0xFF0f3460))
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Frecuencia de Palabras", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp, modifier = Modifier.weight(1f))
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, null, tint = Accent)
                    }
                }

                // Search
                OutlinedTextField(
                    value = search,
                    onValueChange = { search = it },
                    modifier = Modifier.fillMaxWidth().padding(12.dp),
                    placeholder = { Text("Buscar palabra...", color = Color.White.copy(0.4f)) },
                    leadingIcon = { Icon(Icons.Default.Search, null, tint = AccentBlue) },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = Accent,
                        unfocusedBorderColor = Color.White.copy(0.2f),
                        cursorColor = Accent
                    ),
                    shape = RoundedCornerShape(10.dp),
                    singleLine = true
                )

                // Header
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp)
                ) {
                    Text("#", color = AccentBlue, fontSize = 11.sp, fontWeight = FontWeight.Bold, modifier = Modifier.width(36.dp))
                    Text("Palabra", color = AccentBlue, fontSize = 11.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    Text("Veces", color = AccentBlue, fontSize = 11.sp, fontWeight = FontWeight.Bold, modifier = Modifier.width(55.dp), textAlign = TextAlign.End)
                    Spacer(Modifier.width(70.dp))
                }
                Divider(color = Color.White.copy(0.1f))

                LazyColumn(Modifier.fillMaxSize().padding(horizontal = 8.dp)) {
                    itemsIndexed(filtered) { index, (word, count) ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .padding(vertical = 5.dp, horizontal = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("${index + 1}", color = Accent, fontSize = 11.sp, modifier = Modifier.width(36.dp))
                            Text(word, color = Color.White, fontSize = 13.sp, modifier = Modifier.weight(1f))
                            Text("$count", color = AccentYellow, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.width(55.dp), textAlign = TextAlign.End)
                            Spacer(Modifier.width(8.dp))
                            Box(
                                Modifier
                                    .width(60.dp)
                                    .height(10.dp)
                                    .background(Color.White.copy(0.08f), RoundedCornerShape(5.dp))
                            ) {
                                Box(
                                    Modifier
                                        .fillMaxHeight()
                                        .fillMaxWidth(count.toFloat() / maxVal)
                                        .background(Accent.copy(0.7f), RoundedCornerShape(5.dp))
                                )
                            }
                        }
                        Divider(color = Color.White.copy(0.05f))
                    }
                }
            }
        }
    }
}
