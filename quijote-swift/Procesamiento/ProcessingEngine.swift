import Foundation

struct ProcessingResult {
    let wordCount: Int
    let sentenceCount: Int
    let paragraphCount: Int
    let wordFrequency: [(word: String, count: Int)]
    let processingTimeMs: Double
}

// ── Resultado por chunk ───────────────────────────────────────────────────────
private struct ChunkResult {
    // ── Conteo con clave UInt64 (FNV-1a hash) ────────────────────────────────
    // CLAVE: No hay String en el hot path.
    // [UInt64: Int32] vs [String: Int]:
    //   • UInt64 key hash  = 1 instrucción MUL en ARM
    //   • String key hash  = SipHash sobre N bytes + ARC retain/release
    //   • String dict op   ≈ 400ns   →   UInt64 dict op ≈ 50ns  (8× más rápido)
    var counts:   [UInt64: Int32] = [:]

    // ── Bytes de palabras únicas (un pool por chunk, sin String) ─────────────
    // Bytes de las ~18k palabras únicas concatenados, sin allocations intermedias.
    // String se crea solo al final del merge (22k total, no 380k).
    var wordPool: ContiguousArray<UInt8> = []

    // Hash → (offset en pool, longitud)
    var wordInfo: [UInt64: (Int32, Int16)] = [:]

    var sentCount: Int = 0
    var wordCount: Int = 0
}

class ProcessingEngine {

    static func process(text: String) -> ProcessingResult {
        let t0    = CFAbsoluteTimeGetCurrent()
        let cores = ProcessInfo.processInfo.activeProcessorCount

        // ── Obtener bytes UTF-8 sin copia cuando sea posible ─────────────────
        // withUTF8: da acceso directo al buffer interno del String.
        // Para Strings cargados con String(contentsOf:encoding:.utf8) (nuestro caso),
        // esto es zero-copy — el puntero apunta a la memoria ya existente.
        var wordFrequency: [(word: String, count: Int)] = []
        var wordCount    = 0
        var sentenceCount = 0
        var paragraphCount = 0

        // withUTF8 es mutating (puede transcodificar internamente) → necesita var
        var mutableText = text
        mutableText.withUTF8 { buffer in
            let ptr = buffer.baseAddress!
            let len = buffer.count
            let splits = wordBoundarySplits(ptr, len, cores)

            // ── Párrafos: lanzar concurrentemente CON los chunks ──────────────
            // Aprovechamos que GCD tiene más hilos que cores para solaparlo.
            let paraGroup = DispatchGroup()
            nonisolated(unsafe) var paraCount = 0
            paraGroup.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                paraCount = countParagraphs(ptr, len)
                paraGroup.leave()
            }

            // ── Chunks en paralelo ────────────────────────────────────────────
            // Cada chunk: oraciones + palabras con clave UInt64 (sin String)
            var results = [ChunkResult](repeating: ChunkResult(), count: cores)
            results.withUnsafeMutableBufferPointer { buf in
                DispatchQueue.concurrentPerform(iterations: cores) { i in
                    buf[i] = processChunk(ptr, splits[i], splits[i + 1])
                }
            }

            paraGroup.wait()
            paragraphCount = paraCount

            // ── Merge de conteos: solo operaciones UInt64 (sin String) ────────
            sentenceCount = results.reduce(0) { $0 + $1.sentCount }
            wordCount     = results.reduce(0) { $0 + $1.wordCount }

            // Capacidad pre-reservada = cero rehashing durante el merge
            var mergedCounts = [UInt64: Int32](minimumCapacity: 32_000)
            for r in results {
                for (hash, count) in r.counts {
                    mergedCounts[hash, default: 0] += count
                }
            }

            // ── Construir output: UN String por palabra única ─────────────────
            // Antes: 380k String allocations (una por ocurrencia)
            // Ahora:  22k String allocations (una por palabra única) → 17× menos
            wordFrequency.reserveCapacity(mergedCounts.count)

            for (hash, total) in mergedCounts {
                // Encontrar los bytes de esta palabra en el primer chunk que la vio
                for r in results {
                    if let (off, wlen) = r.wordInfo[hash] {
                        r.wordPool.withUnsafeBufferPointer { pool in
                            let word = String(
                                decoding: UnsafeBufferPointer(
                                    start: pool.baseAddress! + Int(off),
                                    count: Int(wlen)
                                ),
                                as: UTF8.self
                            )
                            wordFrequency.append((word, Int(total)))
                        }
                        break
                    }
                }
            }
        }

        // ── Ordenar ───────────────────────────────────────────────────────────
        wordFrequency.sort { $0.count > $1.count }

        return ProcessingResult(
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            paragraphCount: paragraphCount,
            wordFrequency: wordFrequency,
            processingTimeMs: (CFAbsoluteTimeGetCurrent() - t0) * 1000.0
        )
    }

    // ── Worker: procesa el slice [start, end) ─────────────────────────────────
    private static func processChunk(
        _ base: UnsafePointer<UInt8>, _ start: Int, _ end: Int
    ) -> ChunkResult {

        // Diccionarios pre-dimensionados → cero rehashing para el Quijote
        var counts   = [UInt64: Int32](minimumCapacity: 20_000)
        var wordInfo = [UInt64: (Int32, Int16)](minimumCapacity: 20_000)

        // Pool de bytes de palabras únicas.
        // ~15k palabras × 8 bytes promedio = 120KB por chunk → cabe en L2 cache.
        var wordPool = ContiguousArray<UInt8>()
        wordPool.reserveCapacity(131_072)  // 128KB

        var wordCount = 0
        var sentCount = 0
        var inPunct   = false

        // Buffer local para la palabra actual (ya en minúsculas).
        // 64 bytes en stack lógico: reusado para TODAS las palabras del chunk.
        var buf    = ContiguousArray<UInt8>(repeating: 0, count: 64)
        var bufLen = 0

        // Acceso por puntero al buffer de palabras: elimina bounds-check en el inner loop.
        buf.withUnsafeMutableBufferPointer { wptr in
            let wbase = wptr.baseAddress!
            var i = start

            while i < end {
                let b = base[i]  // Raw pointer — cero overhead de CharSequence

                // ── Oraciones ─────────────────────────────────────────────────
                // Solo bytes ASCII: comparaciones directas de UInt8 (costo: 1 ciclo)
                if b == 0x2E || b == 0x21 || b == 0x3F {      // . ! ?
                    if !inPunct { sentCount &+= 1; inPunct = true }
                } else if b > 0x20 {
                    inPunct = false
                }

                // ── Detección de letra ────────────────────────────────────────
                // ASCII a-z / A-Z  ó  byte >= 0x80 (parte de secuencia UTF-8 multibyte)
                // En texto español, todo byte >= 0x80 es una letra acentuada.
                let isLetter = (b >= 0x41 && b <= 0x5A)
                            || (b >= 0x61 && b <= 0x7A)
                            || b >= 0x80

                if isLetter {
                    if bufLen < 64 {
                        // ── Lowercase inline: CERO llamadas a lowercased() ────
                        // 1. ASCII A-Z → a-z: OR 0x20  (1 instrucción ARM: ORR)
                        // 2. Byte de continuación UTF-8 para Á É Ñ Ó Ú Ü, etc.:
                        //    Patrón: 0xC3 seguido de 0x80-0x9E (rango mayúsculas U+00C0-U+00DE)
                        //    Lowercase: OR 0x20 sobre el segundo byte
                        //    Excluir 0x97 (×, que no es letra)
                        // 3. Todo lo demás: copiar (ya en minúscula o byte lead)
                        if b >= 0x41 && b <= 0x5A {
                            wbase[bufLen] = b | 0x20
                        } else if bufLen > 0
                               && wbase[bufLen &- 1] == 0xC3
                               && b >= 0x80 && b <= 0x9E
                               && b != 0x97 {
                            wbase[bufLen] = b | 0x20
                        } else {
                            wbase[bufLen] = b
                        }
                        bufLen &+= 1
                    }
                } else if bufLen > 0 {
                    // ── Fin de palabra: hash FNV-1a inline ────────────────────
                    // FNV-1a: rápido, buena distribución, sin librería externa.
                    // Inline (no función) para que el compilador pueda fusionarlo
                    // con el loop circundante y hacer register allocation óptima.
                    var h: UInt64 = 14_695_981_039_346_656_037
                    var j = 0
                    while j < bufLen {
                        h ^= UInt64(wbase[j])
                        h = h &* 1_099_511_628_211
                        j &+= 1
                    }
                    if h == 0 { h = 1 }  // 0 reservado como "slot vacío"

                    // Incrementar conteo (clave UInt64 → sin ARC, sin SipHash de String)
                    counts[h, default: 0] &+= 1

                    // Guardar bytes solo en PRIMERA ocurrencia de esta palabra
                    // Todas las ocurrencias subsiguientes → solo +=1 en counts (línea de arriba)
                    if wordInfo[h] == nil {
                        let off = Int32(wordPool.count)
                        // append(contentsOf: UnsafeBufferPointer) → memcpy directo en ARM
                        wordPool.append(
                            contentsOf: UnsafeBufferPointer(start: wbase, count: bufLen)
                        )
                        wordInfo[h] = (off, Int16(bufLen))
                    }

                    wordCount &+= 1
                    bufLen = 0
                }

                i &+= 1  // &+ = sin overflow-check (el compilador omite trap instruction)
            }

            // ── Última palabra si el chunk termina en letra ────────────────────
            if bufLen > 0 {
                var h: UInt64 = 14_695_981_039_346_656_037
                var j = 0
                while j < bufLen {
                    h ^= UInt64(wbase[j])
                    h = h &* 1_099_511_628_211
                    j &+= 1
                }
                if h == 0 { h = 1 }
                counts[h, default: 0] &+= 1
                if wordInfo[h] == nil {
                    let off = Int32(wordPool.count)
                    wordPool.append(
                        contentsOf: UnsafeBufferPointer(start: wbase, count: bufLen)
                    )
                    wordInfo[h] = (off, Int16(bufLen))
                }
                wordCount &+= 1
            }
        }

        return ChunkResult(
            counts:    counts,
            wordPool:  wordPool,
            wordInfo:  wordInfo,
            sentCount: sentCount,
            wordCount: wordCount
        )
    }

    // ── Párrafos: scan lineal sobre bytes ─────────────────────────────────────
    private static func countParagraphs(_ base: UnsafePointer<UInt8>, _ len: Int) -> Int {
        var count          = 0
        var prevWasBlank   = true
        var lineHasContent = false
        var i = 0
        while i < len {
            let b = base[i]
            if b == 0x0A {                          // \n
                if lineHasContent && prevWasBlank { count &+= 1 }
                prevWasBlank   = !lineHasContent
                lineHasContent = false
            } else if b > 0x20 && b != 0x0D {      // carácter visible
                lineHasContent = true
            }
            i &+= 1
        }
        if lineHasContent && prevWasBlank { count &+= 1 }
        return count
    }

    // ── Puntos de corte en límites de palabras ────────────────────────────────
    // Nunca cortar en medio de una letra ni de una secuencia UTF-8 multibyte.
    private static func wordBoundarySplits(
        _ base: UnsafePointer<UInt8>, _ len: Int, _ n: Int
    ) -> [Int] {
        var pts   = [Int](repeating: 0, count: n + 1)
        pts[0]    = 0
        pts[n]    = len
        let chunk = len / n
        for i in 1..<n {
            var pos = i * chunk
            while pos < len {
                let b = base[pos]
                let isLetter = (b >= 0x41 && b <= 0x5A)
                            || (b >= 0x61 && b <= 0x7A)
                            || b >= 0x80
                if !isLetter { break }
                pos &+= 1
            }
            pts[i] = pos
        }
        return pts
    }
}
