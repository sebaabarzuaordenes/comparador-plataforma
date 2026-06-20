export interface ProcessingResult {
  wordCount: number;
  sentenceCount: number;
  paragraphCount: number;
  wordFrequency: Array<{ word: string; count: number }>;
  processingTimeMs: number;
}

export function processText(text: string): ProcessingResult {
  const start = performance.now();

  // ── Párrafos: contar sin split() ──────────────────────────────────────────
  let paragraphCount = 0;
  let prevBlank = true;
  let lineStart = 0;
  for (let i = 0; i <= text.length; i++) {
    if (i === text.length || text[i] === '\n') {
      const line = text.slice(lineStart, i).trim();
      const isBlank = line.length === 0;
      if (!isBlank && prevBlank) paragraphCount++;
      prevBlank = isBlank;
      lineStart = i + 1;
    }
  }

  // ── Oraciones: scan de caracteres ─────────────────────────────────────────
  let sentenceCount = 0;
  let inPunct = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '.' || c === '!' || c === '?') {
      if (!inPunct) { sentenceCount++; inPunct = true; }
    } else if (c !== ' ' && c !== '\n' && c !== '\r' && c !== '\t') {
      inPunct = false;
    }
  }

  // ── Palabras + frecuencia: un solo paso sin array intermedio ──────────────
  const freqMap: Record<string, number> = Object.create(null);
  let wordCount = 0;
  let wordStart = -1;
  const LETTER = /\p{L}/u;

  for (let i = 0; i <= text.length; i++) {
    const isLetter = i < text.length && LETTER.test(text[i]);
    if (isLetter) {
      if (wordStart === -1) wordStart = i;
    } else {
      if (wordStart !== -1) {
        const w = text.slice(wordStart, i).toLowerCase();
        freqMap[w] = (freqMap[w] ?? 0) + 1;
        wordCount++;
        wordStart = -1;
      }
    }
  }

  // ── Ordenar por frecuencia ─────────────────────────────────────────────────
  const wordFrequency = Object.entries(freqMap)
    .map(([word, count]) => ({ word, count }))
    .sort((a, b) => b.count - a.count);

  const processingTimeMs = performance.now() - start;

  return { wordCount, sentenceCount, paragraphCount, wordFrequency, processingTimeMs };
}
