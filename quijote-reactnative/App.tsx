import React, { useState, useCallback } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TouchableOpacity,
  ActivityIndicator, Modal, TextInput, FlatList,
  Dimensions, Platform,
} from 'react-native';
import { processText, ProcessingResult } from './src/ProcessingEngine';
// El texto se importa como string (debe configurarse con Metro bundler o @dr.pogodin/react-native-fs)
const quijoteText = require('./quijote.txt');

const { width } = Dimensions.get('window');

const COLORS = {
  bg: '#1a1a2e',
  card: '#16213e',
  accent: '#e94560',
  green: '#06d6a0',
  yellow: '#ffd166',
  blue: '#a8dadc',
  white: '#ffffff',
};

export default function App() {
  const [result, setResult] = useState<ProcessingResult | null>(null);
  const [processing, setProcessing] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [search, setSearch] = useState('');

  const handleProcess = useCallback(async () => {
    setProcessing(true);
    await new Promise(r => setTimeout(r, 50)); // Permitir re-render
    const text = typeof quijoteText === 'string' ? quijoteText : '';
    const r = processText(text);
    setResult(r);
    setProcessing(false);
  }, []);

  const filtered = result
    ? search
      ? result.wordFrequency.filter(w => w.word.includes(search.toLowerCase()))
      : result.wordFrequency
    : [];

  const maxCount = result?.wordFrequency[0]?.count || 1;

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Header */}
        <Text style={styles.emoji}>🔍</Text>
        <Text style={styles.title}>Procesamiento</Text>
        <Text style={styles.subtitle}>Don Quijote de la Mancha</Text>

        {/* Botón */}
        <TouchableOpacity
          style={[styles.button, processing && styles.buttonDisabled]}
          onPress={handleProcess}
          disabled={processing}
        >
          {processing ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.buttonText}>▶  Procesar Texto</Text>
          )}
        </TouchableOpacity>

        {processing && (
          <Text style={styles.processingText}>Analizando texto...</Text>
        )}

        {result && (
          <>
            {/* Tiempo */}
            <View style={styles.timeBox}>
              <Text style={styles.timeLabel}>⏱ Tiempo de procesamiento:</Text>
              <Text style={styles.timeValue}>{result.processingTimeMs.toFixed(2)} ms</Text>
            </View>

            {/* Stats grid */}
            <View style={styles.grid}>
              <StatCard icon="📝" label="Palabras" value={result.wordCount} color={COLORS.accent} />
              <StatCard icon="📖" label="Oraciones" value={result.sentenceCount} color={COLORS.green} />
            </View>
            <View style={styles.grid}>
              <StatCard icon="📄" label="Párrafos" value={result.paragraphCount} color={COLORS.yellow} />
              <StatCard icon="🔤" label="Únicas" value={result.wordFrequency.length} color={COLORS.blue} />
            </View>

            {/* Top 10 */}
            <View style={styles.chartCard}>
              <Text style={styles.chartTitle}>Top 10 Palabras Más Frecuentes</Text>
              {result.wordFrequency.slice(0, 10).map(item => (
                <View key={item.word} style={styles.barRow}>
                  <Text style={styles.barLabel}>{item.word}</Text>
                  <View style={styles.barTrack}>
                    <View
                      style={[
                        styles.barFill,
                        { width: `${(item.count / maxCount) * 100}%` as any },
                      ]}
                    />
                  </View>
                  <Text style={styles.barCount}>{item.count}</Text>
                </View>
              ))}
            </View>

            {/* Botón modal */}
            <TouchableOpacity style={styles.modalButton} onPress={() => setShowModal(true)}>
              <Text style={styles.modalButtonText}>
                📋  Ver Todas las Palabras ({result.wordFrequency.length})
              </Text>
            </TouchableOpacity>
          </>
        )}
      </ScrollView>

      {/* Modal */}
      <Modal visible={showModal} animationType="slide" onRequestClose={() => setShowModal(false)}>
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Frecuencia de Palabras</Text>
            <TouchableOpacity onPress={() => setShowModal(false)}>
              <Text style={styles.closeBtn}>✕</Text>
            </TouchableOpacity>
          </View>

          <TextInput
            style={styles.searchInput}
            value={search}
            onChangeText={setSearch}
            placeholder="Buscar palabra..."
            placeholderTextColor="#ffffff55"
          />

          <View style={styles.tableHeader}>
            <Text style={[styles.tableCell, { width: 36, color: COLORS.blue }]}>#</Text>
            <Text style={[styles.tableCell, { flex: 1, color: COLORS.blue }]}>Palabra</Text>
            <Text style={[styles.tableCell, { width: 55, textAlign: 'right', color: COLORS.blue }]}>Veces</Text>
            <Text style={[styles.tableCell, { width: 70, color: COLORS.blue }]}>  Barra</Text>
          </View>

          <FlatList
            data={filtered}
            keyExtractor={item => item.word}
            renderItem={({ item, index }) => (
              <View style={styles.tableRow}>
                <Text style={[styles.tableCell, { width: 36, color: COLORS.accent }]}>{index + 1}</Text>
                <Text style={[styles.tableCell, { flex: 1, color: COLORS.white }]}>{item.word}</Text>
                <Text style={[styles.tableCell, { width: 55, textAlign: 'right', color: COLORS.yellow }]}>
                  {item.count}
                </Text>
                <View style={[styles.miniBar]}>
                  <View
                    style={[
                      styles.miniBarFill,
                      { width: `${(item.count / maxCount) * 100}%` as any },
                    ]}
                  />
                </View>
              </View>
            )}
            ItemSeparatorComponent={() => <View style={{ height: 1, backgroundColor: '#ffffff10' }} />}
          />
        </View>
      </Modal>
    </View>
  );
}

function StatCard({ icon, label, value, color }: { icon: string; label: string; value: number; color: string }) {
  return (
    <View style={[styles.statCard]}>
      <Text style={styles.statIcon}>{icon}</Text>
      <Text style={[styles.statValue, { color }]}>{value.toLocaleString()}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bg },
  scroll: { padding: 20, alignItems: 'center', paddingTop: Platform.OS === 'ios' ? 60 : 40 },
  emoji: { fontSize: 48 },
  title: { fontSize: 28, fontWeight: 'bold', color: COLORS.white, marginTop: 8 },
  subtitle: { fontSize: 14, color: COLORS.blue, marginBottom: 24 },
  button: {
    backgroundColor: COLORS.accent, borderRadius: 14, paddingVertical: 16,
    paddingHorizontal: 32, width: '100%', alignItems: 'center', marginBottom: 12,
  },
  buttonDisabled: { backgroundColor: '#555' },
  buttonText: { color: COLORS.white, fontWeight: 'bold', fontSize: 16 },
  processingText: { color: COLORS.blue, fontSize: 13, marginBottom: 12 },
  timeBox: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.08)', borderRadius: 12,
    padding: 14, width: '100%', marginVertical: 8,
  },
  timeLabel: { color: COLORS.white, fontSize: 13 },
  timeValue: { color: COLORS.blue, fontWeight: 'bold', fontSize: 14 },
  grid: { flexDirection: 'row', gap: 12, marginBottom: 12, width: '100%' },
  statCard: {
    flex: 1, backgroundColor: 'rgba(255,255,255,0.08)', borderRadius: 14,
    padding: 16, alignItems: 'center',
  },
  statIcon: { fontSize: 24, marginBottom: 4 },
  statValue: { fontSize: 20, fontWeight: 'bold' },
  statLabel: { fontSize: 11, color: 'rgba(255,255,255,0.6)', marginTop: 2 },
  chartCard: {
    backgroundColor: 'rgba(255,255,255,0.06)', borderRadius: 16,
    padding: 16, width: '100%', marginBottom: 12,
  },
  chartTitle: { color: COLORS.white, fontWeight: 'bold', fontSize: 14, marginBottom: 12 },
  barRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 6 },
  barLabel: { color: COLORS.white, fontSize: 11, width: 80 },
  barTrack: {
    flex: 1, height: 14, backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 7, overflow: 'hidden', marginHorizontal: 8,
  },
  barFill: { height: '100%', backgroundColor: COLORS.accent, borderRadius: 7 },
  barCount: { color: COLORS.blue, fontSize: 11, width: 40, textAlign: 'right' },
  modalButton: {
    borderWidth: 1, borderColor: `${COLORS.blue}88`, borderRadius: 14,
    paddingVertical: 14, width: '100%', alignItems: 'center', marginBottom: 30,
  },
  modalButtonText: { color: COLORS.blue, fontWeight: '600', fontSize: 14 },
  modalContainer: { flex: 1, backgroundColor: COLORS.bg },
  modalHeader: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    backgroundColor: '#0f3460', padding: 16,
    paddingTop: Platform.OS === 'ios' ? 56 : 16,
  },
  modalTitle: { color: COLORS.white, fontWeight: 'bold', fontSize: 18 },
  closeBtn: { color: COLORS.accent, fontSize: 20, fontWeight: 'bold' },
  searchInput: {
    backgroundColor: 'rgba(255,255,255,0.1)', color: COLORS.white,
    margin: 12, borderRadius: 10, paddingHorizontal: 14, paddingVertical: 10, fontSize: 14,
  },
  tableHeader: {
    flexDirection: 'row', paddingHorizontal: 12, paddingBottom: 8,
    borderBottomWidth: 1, borderBottomColor: 'rgba(255,255,255,0.1)',
  },
  tableRow: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, paddingVertical: 6 },
  tableCell: { fontSize: 12, color: COLORS.white },
  miniBar: {
    width: 60, height: 10, backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 5, overflow: 'hidden', marginLeft: 8,
  },
  miniBarFill: { height: '100%', backgroundColor: `${COLORS.accent}BB`, borderRadius: 5 },
});
