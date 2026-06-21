package net.squirrelweb.quijote_kotlin

import kotlinx.coroutines.*

data class ProcessingResult(
    val wordCount: Int,
    val sentenceCount: Int,
    val paragraphCount: Int,
    val wordFrequency: List<Pair<String, Int>>,
    val processingTimeMs: Long
)

object ProcessingEngine {

    // suspend fun: se llama desde withContext(Dispatchers.Default) en MainActivity,
    // así que podemos lanzar coroutines hijas sin bloquear el hilo.
    suspend fun process(text: String): ProcessingResult = coroutineScope {
        val startTime = System.nanoTime()

        // Una sola conversión a CharArray — acceso O(1) directo sin virtual dispatch
        val chars = text.toCharArray()
        val len = chars.size

        // Usar todos los cores disponibles (típico: 6-8 en Android moderno)
        val cores = Runtime.getRuntime().availableProcessors().coerceIn(2, 8)
        val splits = wordBoundarySplits(chars, len, cores)

        // ── Lanzar N workers de oraciones+palabras EN PARALELO ───────────────
        // Cada worker procesa su chunk de forma completamente independiente.
        val chunkJobs = (0 until cores).map { c ->
            async(Dispatchers.Default) {
                processChunk(chars, splits[c], splits[c + 1])
            }
        }

        // ── Párrafos: concurrente con los workers de arriba ──────────────────
        // Requiere contexto entre líneas → scan secuencial, pero corre en paralelo
        // con los chunkJobs aprovechando que todos leen el mismo CharArray (inmutable).
        val paraJob = async(Dispatchers.Default) { countParagraphs(chars, len) }

        // ── Esperar todos los resultados ─────────────────────────────────────
        val chunks = chunkJobs.awaitAll()
        val paragraphCount = paraJob.await()

        // ── Merge: sumar conteos de oraciones ────────────────────────────────
        val sentenceCount = chunks.sumOf { it.sentenceCount }

        // ── Merge: combinar mapas de frecuencia ──────────────────────────────
        // Usar el primer mapa (el más grande) como destino para minimizar iteraciones
        val merged = chunks[0].freqMap
        for (i in 1 until chunks.size) {
            for ((word, count) in chunks[i].freqMap) {
                merged[word] = (merged[word] ?: 0) + count
            }
        }

        val wordCount = chunks.sumOf { it.wordCount }

        // ── Ordenar por frecuencia descendente ───────────────────────────────
        val wordFrequency = merged.entries
            .sortedByDescending { it.value }
            .map { Pair(it.key, it.value) }

        val elapsed = (System.nanoTime() - startTime) / 1_000_000L

        ProcessingResult(
            wordCount = wordCount,
            sentenceCount = sentenceCount,
            paragraphCount = paragraphCount,
            wordFrequency = wordFrequency,
            processingTimeMs = elapsed
        )
    }

    // ── Resultado de un chunk ─────────────────────────────────────────────────
    private data class ChunkResult(
        val sentenceCount: Int,
        val wordCount: Int,
        val freqMap: HashMap<String, Int>
    )

    // ── Worker: procesa un slice [start, end) del CharArray ──────────────────
    private fun processChunk(chars: CharArray, start: Int, end: Int): ChunkResult {
        val map = HashMap<String, Int>(8_000)
        val buf = CharArray(64)   // buffer reutilizable — cero allocs de substrings
        var bufLen = 0
        var wordCount = 0
        var sentenceCount = 0
        var inPunct = false

        for (i in start until end) {
            val c = chars[i]
            val v = c.code

            // Oraciones
            if (c == '.' || c == '!' || c == '?') {
                if (!inPunct) { sentenceCount++; inPunct = true }
            } else if (v > 0x20 && c != '\r') {
                inPunct = false
            }

            // Palabras
            if (isLetter(v)) {
                if (bufLen < 64) buf[bufLen++] = toLower(v, c)
            } else if (bufLen > 0) {
                val w = String(buf, 0, bufLen)
                map[w] = (map[w] ?: 0) + 1
                wordCount++
                bufLen = 0
            }
        }
        if (bufLen > 0) {
            val w = String(buf, 0, bufLen)
            map[w] = (map[w] ?: 0) + 1
            wordCount++
        }
        return ChunkResult(sentenceCount, wordCount, map)
    }

    // ── Párrafos: scan secuencial (necesita estado entre líneas) ─────────────
    private fun countParagraphs(chars: CharArray, len: Int): Int {
        var count = 0
        var prevWasBlank = true
        var lineHasContent = false
        for (i in 0 until len) {
            val c = chars[i]
            val v = c.code
            if (c == '\n') {
                if (lineHasContent && prevWasBlank) count++
                prevWasBlank = !lineHasContent
                lineHasContent = false
            } else if (v > 0x20 && c != '\r') {
                lineHasContent = true
            }
        }
        if (lineHasContent && prevWasBlank) count++
        return count
    }

    // ── Encontrar puntos de corte en límites de palabras ─────────────────────
    private fun wordBoundarySplits(chars: CharArray, len: Int, n: Int): IntArray {
        val pts = IntArray(n + 1)
        pts[0] = 0
        pts[n] = len
        val chunk = len / n
        for (i in 1 until n) {
            var pos = i * chunk
            // Avanzar hasta el próximo no-letra para no partir palabras
            while (pos < len && isLetter(chars[pos].code)) pos++
            pts[i] = pos
        }
        return pts
    }

    private fun isLetter(v: Int): Boolean =
        (v in 65..90) || (v in 97..122) || (v in 0x00C0..0x024F)

    private fun toLower(v: Int, c: Char): Char =
        if (v in 65..90) (v or 0x20).toChar() else c.lowercaseChar()
}
