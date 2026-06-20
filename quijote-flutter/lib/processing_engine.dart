class ProcessingResult {
  final int wordCount;
  final int sentenceCount;
  final int paragraphCount;
  final List<MapEntry<String, int>> wordFrequency;
  final double processingTimeMs;

  const ProcessingResult({
    required this.wordCount,
    required this.sentenceCount,
    required this.paragraphCount,
    required this.wordFrequency,
    required this.processingTimeMs,
  });
}

class ProcessingEngine {
  static ProcessingResult process(String text) {
    final stopwatch = Stopwatch()..start();

    // ── Párrafos: contar sin split() ────────────────────────────────────────
    int paragraphCount = 0;
    bool prevBlank = true;
    int lineStart = 0;
    for (int i = 0; i <= text.length; i++) {
      if (i == text.length || text[i] == '\n') {
        final line = text.substring(lineStart, i).trim();
        final isBlank = line.isEmpty;
        if (!isBlank && prevBlank) paragraphCount++;
        prevBlank = isBlank;
        lineStart = i + 1;
      }
    }

    // ── Oraciones: scan de caracteres ───────────────────────────────────────
    int sentenceCount = 0;
    bool inPunct = false;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '.' || c == '!' || c == '?') {
        if (!inPunct) { sentenceCount++; inPunct = true; }
      } else if (c != ' ' && c != '\n' && c != '\r' && c != '\t') {
        inPunct = false;
      }
    }

    // ── Palabras + frecuencia: un solo paso sin listas intermedias ───────────
    final freqMap = <String, int>{};
    int wordCount = 0;
    int wordStart = -1;

    for (int i = 0; i <= text.length; i++) {
      final isLetter = i < text.length && _isLetter(text.codeUnitAt(i));
      if (isLetter) {
        if (wordStart == -1) wordStart = i;
      } else {
        if (wordStart != -1) {
          final w = text.substring(wordStart, i).toLowerCase();
          freqMap[w] = (freqMap[w] ?? 0) + 1;
          wordCount++;
          wordStart = -1;
        }
      }
    }

    // ── Ordenar por frecuencia ───────────────────────────────────────────────
    final wordFrequency = freqMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    stopwatch.stop();

    return ProcessingResult(
      wordCount: wordCount,
      sentenceCount: sentenceCount,
      paragraphCount: paragraphCount,
      wordFrequency: wordFrequency,
      processingTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
    );
  }

  // Detecta letras Unicode sin regex (cubre latín, español, etc.)
  static bool _isLetter(int codeUnit) {
    // Básico Latin (a-z, A-Z)
    if ((codeUnit >= 65 && codeUnit <= 90) || (codeUnit >= 97 && codeUnit <= 122)) return true;
    // Latín extendido (acentos, ñ, ü, etc.) — U+00C0 a U+024F
    if (codeUnit >= 0x00C0 && codeUnit <= 0x024F) return true;
    // Alfabetos adicionales comunes
    if (codeUnit >= 0x0400 && codeUnit <= 0x04FF) return true; // Cirílico
    if (codeUnit >= 0x0600 && codeUnit <= 0x06FF) return true; // Árabe
    return false;
  }
}
