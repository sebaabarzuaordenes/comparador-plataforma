using System;
using System.Collections.Generic;
using System.Linq;

namespace Procesamiento;

public record ProcessingResult(
    int WordCount,
    int SentenceCount,
    int ParagraphCount,
    List<(string Word, int Count)> WordFrequency,
    double ProcessingTimeMs
);

public static class ProcessingEngine
{
    public static ProcessingResult Process(string text)
    {
        var sw = System.Diagnostics.Stopwatch.StartNew();

        // ── Párrafos: contar sin Split() ────────────────────────────────────
        int paragraphCount = 0;
        bool prevBlank = true;
        int lineStart = 0;
        for (int i = 0; i <= text.Length; i++)
        {
            if (i == text.Length || text[i] == '\n')
            {
                bool isBlank = string.IsNullOrWhiteSpace(text.AsSpan(lineStart, i - lineStart).ToString());
                if (!isBlank && prevBlank) paragraphCount++;
                prevBlank = isBlank;
                lineStart = i + 1;
            }
        }

        // ── Oraciones: scan de caracteres ───────────────────────────────────
        int sentenceCount = 0;
        bool inPunct = false;
        foreach (char c in text)
        {
            if (c == '.' || c == '!' || c == '?')
            {
                if (!inPunct) { sentenceCount++; inPunct = true; }
            }
            else if (!char.IsWhiteSpace(c))
            {
                inPunct = false;
            }
        }

        // ── Palabras + frecuencia: un solo paso ─────────────────────────────
        var freqMap = new Dictionary<string, int>(32_000, StringComparer.OrdinalIgnoreCase);
        int wordCount = 0;
        int wordStart = -1;

        for (int i = 0; i <= text.Length; i++)
        {
            bool isLetter = i < text.Length && char.IsLetter(text[i]);
            if (isLetter)
            {
                if (wordStart == -1) wordStart = i;
            }
            else if (wordStart != -1)
            {
                string w = text.Substring(wordStart, i - wordStart).ToLowerInvariant();
                freqMap.TryGetValue(w, out int cur);
                freqMap[w] = cur + 1;
                wordCount++;
                wordStart = -1;
            }
        }

        // ── Ordenar por frecuencia ───────────────────────────────────────────
        var wordFrequency = freqMap
            .OrderByDescending(kv => kv.Value)
            .Select(kv => (kv.Key, kv.Value))
            .ToList();

        sw.Stop();

        return new ProcessingResult(wordCount, sentenceCount, paragraphCount, wordFrequency, sw.Elapsed.TotalMilliseconds);
    }
}
