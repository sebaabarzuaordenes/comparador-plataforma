import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'processing_engine.dart';

void main() => runApp(const ProcesamientoApp());

class ProcesamientoApp extends StatelessWidget {
  const ProcesamientoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Procesamiento',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1a1a2e),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFe94560),
            surface: Color(0xFF16213e),
          ),
        ),
        home: const HomePage(),
      );
}

// Función top-level para usar con Isolate
ProcessingResult _processInIsolate(String text) {
  return ProcessingEngine.process(text);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ProcessingResult? _result;
  bool _processing = false;
  String? _error;

  static const _accent = Color(0xFFe94560);
  static const _green = Color(0xFF06d6a0);
  static const _yellow = Color(0xFFffd166);
  static const _blue = Color(0xFFa8dadc);

  Future<void> _process() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 30));

    try {
      final text = await rootBundle.loadString('assets/quijote.txt');
      final result = await compute(_processInIsolate, text);

      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo procesar el texto: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text('🔍', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                const Text('Procesamiento',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Don Quijote de la Mancha',
                    style: TextStyle(fontSize: 14, color: _blue)),
                const SizedBox(height: 24),

                // Botón procesar
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : _process,
                    icon: _processing
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(_processing ? 'Procesando...' : 'Procesar Texto',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),

                if (_processing) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(color: _accent, backgroundColor: Color(0x22e94560)),
                  const SizedBox(height: 6),
                  const Text('Analizando texto...', style: TextStyle(color: _blue, fontSize: 13)),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: _yellow, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],

                if (_result != null) ...[
                  const SizedBox(height: 16),

                  // Tiempo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: _accent),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Tiempo de procesamiento:', style: TextStyle(color: Colors.white, fontSize: 13))),
                        Text('${_result!.processingTimeMs.toStringAsFixed(2)} ms',
                            style: const TextStyle(color: _blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Stats grid
                  Row(children: [
                    _StatCard(icon: Icons.text_fields, label: 'Palabras', value: _result!.wordCount, color: _accent),
                    const SizedBox(width: 12),
                    _StatCard(icon: Icons.format_align_left, label: 'Oraciones', value: _result!.sentenceCount, color: _green),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _StatCard(icon: Icons.article, label: 'Párrafos', value: _result!.paragraphCount, color: _yellow),
                    const SizedBox(width: 12),
                    _StatCard(icon: Icons.list, label: 'Únicas', value: _result!.wordFrequency.length, color: _blue),
                  ]),

                  const SizedBox(height: 14),

                  // Top 10 chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top 10 Palabras Más Frecuentes',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._result!.wordFrequency.take(10).map((e) => _BarRow(
                          word: e.key,
                          count: e.value,
                          maxCount: _result!.wordFrequency.first.value,
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botón modal
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _showWordModal(context),
                      icon: const Icon(Icons.list, color: _blue),
                      label: Text(
                        'Ver Todas las Palabras (${_result!.wordFrequency.length})',
                        style: const TextStyle(color: _blue, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x88a8dadc)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordFrequencyModal(wordFrequency: _result!.wordFrequency),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            _fmt(value),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0x99ffffff))),
        ],
      ),
    ),
  );

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _BarRow extends StatelessWidget {
  final String word;
  final int count;
  final int maxCount;

  const _BarRow({required this.word, required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(word, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(
              value: maxCount > 0 ? count / maxCount : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFe94560)),
              minHeight: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text('$count', style: const TextStyle(color: Color(0xFFa8dadc), fontSize: 11), textAlign: TextAlign.right),
        ),
      ],
    ),
  );
}

// MODAL
class WordFrequencyModal extends StatefulWidget {
  final List<MapEntry<String, int>> wordFrequency;
  const WordFrequencyModal({super.key, required this.wordFrequency});

  @override
  State<WordFrequencyModal> createState() => _WordFrequencyModalState();
}

class _WordFrequencyModalState extends State<WordFrequencyModal> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? widget.wordFrequency
        : widget.wordFrequency.where((e) => e.key.contains(_search.toLowerCase())).toList();
    final maxCount = widget.wordFrequency.isNotEmpty ? widget.wordFrequency.first.value : 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      maxChildSize: 0.98,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Frecuencia de Palabras',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFe94560)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar palabra...',
                  hintStyle: const TextStyle(color: Color(0x55ffffff)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFa8dadc)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            // Header tabla
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 36, child: Text('#', style: TextStyle(color: Color(0xFFa8dadc), fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Palabra', style: TextStyle(color: Color(0xFFa8dadc), fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 55, child: Text('Veces', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFFa8dadc), fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 70, child: Text('  Barra', style: TextStyle(color: Color(0xFFa8dadc), fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(color: Color(0x22ffffff)),

            // Lista
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x0fffffff)),
                itemBuilder: (_, index) {
                  final e = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(width: 36, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFFe94560), fontSize: 11))),
                        Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                        SizedBox(
                          width: 55,
                          child: Text('${e.value}', textAlign: TextAlign.right,
                              style: const TextStyle(color: Color(0xFFffd166), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60, height: 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: maxCount > 0 ? e.value / maxCount : 0,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation(Color(0xBBe94560)),
                              minHeight: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
