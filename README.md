# Procesamiento — Comparador de Plataformas Móviles

Proyecto que implementa la **misma aplicación en 5 plataformas** para comparar rendimiento real en dispositivos móviles. La app procesa el texto completo de *El Quijote de la Mancha* (~380.000 palabras, ~2 MB) y mide el tiempo de ejecución de cada plataforma.

---

## ¿Qué hace la app?

1. Carga el texto completo de Don Quijote desde un asset local
2. Cuenta palabras, oraciones y párrafos
3. Calcula la frecuencia de cada palabra (ranking completo)
4. Mide el tiempo de procesamiento en milisegundos
5. Muestra los resultados con gráfico de Top 10 y modal con lista completa y búsqueda

---

## Resultados de rendimiento (iPhone 15 / Pixel 8)

| Plataforma | Tiempo | Hilos |
|---|---|---|
| **iOS Swift (nativa)** | ~60–80 ms | Multi-core GCD |
| **Android Kotlin (nativa)** | ~94 ms | Multi-core Coroutines |
| **Flutter** | ~140 ms | 1 hilo (Dart AOT) |
| **React Native** | ~280 ms | 1 hilo (JS Engine) |
| **.NET MAUI** | ~320 ms | 1 hilo |

> Los nativos usan todos los cores del procesador. Flutter, React Native y MAUI usan un solo hilo.

---

## Estructura del repositorio

```
don-quijote/
├── el quijote  de la mancha.txt   ← Texto fuente original
├── quijote-swift/                 ← iOS nativa (SwiftUI)
├── quijote-kotlin/                ← Android nativa (Kotlin + Jetpack Compose)
├── quijote-reactnative/           ← Híbrida React Native (iOS + Android)
├── quijote-maui/                  ← Híbrida .NET MAUI (iOS + Android)
└── quijote-flutter/               ← Híbrida Flutter (iOS + Android)
```

---

## 1. iOS Nativa — SwiftUI · `quijote-swift/`

**Requisitos:** macOS · Xcode 15+

```bash
cd quijote-swift
open Procesamiento.xcodeproj
```

En Xcode:
- Seleccionar simulador o dispositivo físico
- **Signing & Capabilities** → seleccionar tu Team de desarrollador
- `Cmd + R` para compilar y ejecutar
- Para release: `Product → Archive`

**Tecnología de procesamiento:** `UnsafePointer<UInt8>` sobre el buffer UTF-8 del String (zero-copy), hash FNV-1a con clave `UInt64` para elimininar String del hot path, `DispatchQueue.concurrentPerform` con todos los cores de rendimiento de Apple Silicon.

---

## 2. Android Nativa — Kotlin · `quijote-kotlin/`

**Requisitos:** Android Studio Ladybug+ · JDK 11+

```bash
cd quijote-kotlin

# Compilar APK debug
./gradlew assembleDebug

# Instalar directamente en dispositivo conectado
./gradlew installDebug

# APK release (requiere keystore configurado)
./gradlew assembleRelease
```

El APK debug queda en: `app/build/outputs/apk/debug/app-debug.apk`

También se puede abrir directamente con Android Studio y usar el botón Run ▶.

**Tecnología de procesamiento:** `toCharArray()` para acceso directo sin virtual dispatch de CharSequence, buffer reutilizable de 64 bytes para construir palabras sin substring allocations, `kotlinx.coroutines` con `DispatchQueue.concurrentPerform` equivalente dividiendo el texto en N chunks paralelos.

---

## 3. React Native · `quijote-reactnative/`

**Requisitos:** Node 18+ · npx · Xcode (iOS) · Android Studio (Android)

```bash
cd quijote-reactnative
npm install

# iOS — abrir simulador o dispositivo
npx react-native run-ios

# iOS — build release
npx react-native build-ios --mode Release

# Android — abrir emulador o dispositivo
npx react-native run-android

# Android — APK release
cd android && ./gradlew assembleRelease
```

> El texto de Don Quijote está registrado como asset en `metro.config.js` y se incrusta en el bundle JS automáticamente.

---

## 4. .NET MAUI · `quijote-maui/`

**Requisitos:** .NET 9 SDK · workload MAUI instalado

```bash
# Instalar workload MAUI (solo la primera vez)
dotnet workload install maui

cd quijote-maui/Procesamiento

# iOS (requiere macOS + Xcode)
dotnet build -f net9.0-ios -c Release
dotnet publish -f net9.0-ios -c Release

# Android
dotnet build -f net9.0-android -c Release
dotnet publish -f net9.0-android -c Release
# APK en: bin/Release/net9.0-android/publish/
```

Para desarrollo con hot reload:
```bash
dotnet run -f net9.0-android    # en emulador Android
dotnet run -f net9.0-ios        # en simulador iOS (macOS)
```

---

## 5. Flutter · `quijote-flutter/`

**Requisitos:** Flutter SDK 3.22+ · Dart 3.4+

```bash
cd quijote-flutter
flutter pub get

# Verificar entorno
flutter doctor

# iOS (requiere macOS + Xcode)
flutter run --release                        # en simulador/dispositivo
flutter build ios --release                  # .app para distribución

# Android
flutter run --release                        # en emulador/dispositivo
flutter build apk --release                  # APK
flutter build appbundle --release            # .aab para Google Play
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

---

## Funcionalidades comunes a todas las apps

| Característica | Detalle |
|---|---|
| Conteo de palabras | Tokenización por caracteres Unicode |
| Conteo de oraciones | Detección por `.` `!` `?` sin regex |
| Conteo de párrafos | Separación por líneas en blanco |
| Frecuencia por palabra | Ranking completo ordenado de mayor a menor |
| Tiempo de procesamiento | Medido con precisión de nanosegundos |
| Gráfico Top 10 | Barras proporcionales animadas |
| Modal scrollable | Lista completa con búsqueda en tiempo real |
| UI dark mode | Tema oscuro con gradientes y tarjetas |

---

## Arquitectura del motor de procesamiento

Todas las implementaciones usan el mismo algoritmo optimizado de **una sola pasada** sobre los caracteres, sin expresiones regulares ni frameworks de NLP:

```
texto → bytes raw → scan lineal → hash por palabra → frecuencias → sort
```

Las versiones nativas (Swift y Kotlin) además dividen el texto en N chunks y los procesan en paralelo usando todos los cores disponibles, reduciendo el tiempo de pared por un factor de 4–6×.
