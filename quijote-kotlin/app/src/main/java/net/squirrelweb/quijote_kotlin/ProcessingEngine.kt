package net.squirrelweb.quijote_kotlin

import java.util.Locale

data class ProcessingResult(
    val wordCount: Int,
    val sentenceCount: Int,
    val paragraphCount: Int,
    val wordFrequency: List<Pair<String, Int>>,
    val processingTimeMs: Long
)

object ProcessingEngine {

    fun process(text: String): ProcessingResult {
        val startTime = System.nanoTime()

        // ── Párrafos: contar bloques separados por línea vacía ──────────────
        // Sin split() para evitar crear miles de substrings
        var paragraphCount = 0
        var prevWasBlank = true // empieza en true para no contar línea inicial vacía
        var lineStart = 0
        for (i in text.indices) {
            if (text[i] == '\n' || i == text.lastIndex) {
                val lineEnd = if (i == text.lastIndex) i + 1 else i
                val lineIsBlank = text.substring(lineStart, lineEnd).isBlank()
                if (!lineIsBlank && prevWasBlank) paragraphCount++
                prevWasBlank = lineIsBlank
                lineStart = i + 1
            }
        }

        // ── Oraciones: scan de caracteres sin regex ──────────────────────────
        var sentenceCount = 0
        var inPunct = false
        for (c in text) {
            if (c == '.' || c == '!' || c == '?') {
                if (!inPunct) { sentenceCount++; inPunct = true }
            } else if (!c.isWhitespace()) {
                inPunct = false
            }
        }

        // ── Palabras + frecuencia: un solo paso, sin materializar lista ──────
        // Pre-reservar capacidad para ~80.000 palabras únicas (Quijote tiene ~22k)
        val freqMap = HashMap<String, Int>(32_000)
        var wordCount = 0
        var wordStart = -1

        for (i in text.indices) {
            val c = text[i]
            if (c.isLetter()) {
                if (wordStart == -1) wordStart = i
            } else {
                if (wordStart != -1) {
                    val w = text.substring(wordStart, i).lowercase(Locale.getDefault())
                    freqMap[w] = (freqMap[w] ?: 0) + 1
                    wordCount++
                    wordStart = -1
                }
            }
        }
        // Última palabra si el texto termina en letra
        if (wordStart != -1) {
            val w = text.substring(wordStart).lowercase(Locale.getDefault())
            freqMap[w] = (freqMap[w] ?: 0) + 1
            wordCount++
        }

        // ── Ordenar por frecuencia descendente ───────────────────────────────
        val wordFrequency = freqMap.entries
            .sortedByDescending { it.value }
            .map { Pair(it.key, it.value) }

        val elapsed = (System.nanoTime() - startTime) / 1_000_000L

        return ProcessingResult(
            wordCount = wordCount,
            sentenceCount = sentenceCount,
            paragraphCount = paragraphCount,
            wordFrequency = wordFrequency,
            processingTimeMs = elapsed
        )
    }
}
