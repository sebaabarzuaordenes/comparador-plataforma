import Foundation
import NaturalLanguage

struct ProcessingResult {
    let wordCount: Int
    let sentenceCount: Int
    let paragraphCount: Int
    let wordFrequency: [(word: String, count: Int)]
    let processingTimeMs: Double // milliseconds
}

class ProcessingEngine {

    static func process(text: String) -> ProcessingResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Párrafos: separar por líneas en blanco
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let paragraphCount = paragraphs.count

        // Oraciones: separar por . ! ?
        let sentencePattern = try! NSRegularExpression(pattern: "[.!?]+")
        let range = NSRange(text.startIndex..., in: text)
        let sentenceCount = sentencePattern.numberOfMatches(in: text, range: range)

        // Palabras: tokenizar
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var wordCount = 0
        var freqMap: [String: Int] = [:]

        tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { range, _ in
            let word = text[range].lowercased()
            wordCount += 1
            freqMap[word, default: 0] += 1
            return true
        }

        let sorted = freqMap.sorted { $0.value > $1.value }
        let wordFrequency = sorted.map { (word: $0.key, count: $0.value) }

        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        return ProcessingResult(
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            paragraphCount: paragraphCount,
            wordFrequency: wordFrequency,
            processingTimeMs: elapsedMs
        )
    }
}
