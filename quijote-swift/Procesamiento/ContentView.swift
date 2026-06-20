import SwiftUI
import NaturalLanguage

struct ContentView: View {
    @State private var result: ProcessingResult? = nil
    @State private var isProcessing = false
    @State private var showModal = false
    @State private var progress: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 6) {
                            Image(systemName: "text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "e94560"))
                            Text("Procesamiento")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            Text("Don Quijote de la Mancha")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "a8dadc"))
                        }
                        .padding(.top, 20)

                        // Botón procesar
                        Button(action: startProcessing) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(isProcessing ? "Procesando..." : "Procesar Texto")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isProcessing ? Color.gray : Color(hex: "e94560"))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal)

                        if isProcessing {
                            VStack(spacing: 8) {
                                ProgressView(value: progress)
                                    .tint(Color(hex: "e94560"))
                                    .padding(.horizontal)
                                Text("Analizando texto...")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "a8dadc"))
                            }
                        }

                        // Resultados
                        if let r = result {
                            // Tiempo
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(Color(hex: "e94560"))
                                Text("Tiempo de procesamiento:")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(String(format: "%.2f ms", r.processingTimeMs))
                                    .foregroundColor(Color(hex: "a8dadc"))
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .padding(.horizontal)

                            // Tarjetas de estadísticas
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(icon: "text.word.spacing", label: "Palabras", value: r.wordCount.formatted(), color: "e94560")
                                StatCard(icon: "text.alignleft", label: "Oraciones", value: r.sentenceCount.formatted(), color: "06d6a0")
                                StatCard(icon: "doc.text", label: "Párrafos", value: r.paragraphCount.formatted(), color: "ffd166")
                                StatCard(icon: "list.bullet", label: "Palabras únicas", value: r.wordFrequency.count.formatted(), color: "a8dadc")
                            }
                            .padding(.horizontal)

                            // Top 10 palabras - mini gráfico
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Top 10 Palabras Más Frecuentes")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)

                                let top10 = Array(r.wordFrequency.prefix(10))
                                let maxCount = top10.first?.count ?? 1

                                ForEach(top10, id: \.word) { item in
                                    HStack(spacing: 10) {
                                        Text(item.word)
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 80, alignment: .leading)
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.1))
                                                Capsule()
                                                    .fill(Color(hex: "e94560"))
                                                    .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount))
                                            }
                                        }
                                        .frame(height: 18)
                                        Text("\(item.count)")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "a8dadc"))
                                            .frame(width: 45, alignment: .trailing)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(16)
                            .padding(.horizontal)

                            // Botón ver lista completa
                            Button(action: { showModal = true }) {
                                HStack {
                                    Image(systemName: "list.number")
                                    Text("Ver Todas las Palabras (\(r.wordFrequency.count))")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "0f3460"))
                                .foregroundColor(Color(hex: "a8dadc"))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(hex: "a8dadc").opacity(0.4), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showModal) {
            if let r = result {
                WordFrequencyModal(wordFrequency: r.wordFrequency)
            }
        }
    }

    func startProcessing() {
        isProcessing = true
        progress = 0

        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { t in
            if progress < 0.9 { progress += 0.02 }
            else { t.invalidate() }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "quijote", withExtension: "txt"),
                  let text = try? String(contentsOf: url, encoding: .utf8) else { return }

            let r = ProcessingEngine.process(text: text)

            DispatchQueue.main.async {
                timer.invalidate()
                progress = 1.0
                withAnimation { result = r }
                isProcessing = false
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }
}

// MARK: - Word Frequency Modal
struct WordFrequencyModal: View {
    let wordFrequency: [(word: String, count: Int)]
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss

    var filtered: [(word: String, count: Int)] {
        if searchText.isEmpty { return wordFrequency }
        return wordFrequency.filter { $0.word.contains(searchText.lowercased()) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(hex: "a8dadc"))
                        TextField("Buscar palabra...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding()

                    // Header tabla
                    HStack {
                        Text("#")
                            .frame(width: 40, alignment: .leading)
                        Text("Palabra")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Veces")
                            .frame(width: 70, alignment: .trailing)
                        Text("Barra")
                            .frame(width: 80, alignment: .trailing)
                    }
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "a8dadc"))
                    .padding(.horizontal)
                    .padding(.bottom, 6)

                    Divider().background(Color.white.opacity(0.2))

                    let maxCount = wordFrequency.first?.count ?? 1

                    List {
                        ForEach(Array(filtered.enumerated()), id: \.element.word) { index, item in
                            HStack(spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "e94560"))
                                    .frame(width: 40, alignment: .leading)
                                Text(item.word)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(item.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(Color(hex: "ffd166"))
                                    .frame(width: 55, alignment: .trailing)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.08))
                                        Capsule()
                                            .fill(Color(hex: "e94560").opacity(0.7))
                                            .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount))
                                    }
                                }
                                .frame(width: 60, height: 10)
                            }
                            .listRowBackground(Color.white.opacity(0.03))
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Frecuencia de Palabras")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(Color(hex: "e94560"))
                }
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView()
}
