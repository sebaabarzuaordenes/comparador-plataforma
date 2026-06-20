# Procesamiento — Guía de Compilación

App que procesa el texto de Don Quijote: cuenta palabras, oraciones y párrafos, mide el tiempo de procesamiento y muestra la frecuencia de cada palabra con un modal scrollable.

---

## 1. iOS Nativa (SwiftUI) — `Procesamiento-iOS/`

**Requisitos:** macOS + Xcode 15+

```bash
cd Procesamiento-iOS
open Procesamiento.xcodeproj
```

En Xcode:
- Seleccionar un simulador o dispositivo físico
- Ir a Signing & Capabilities → seleccionar tu Team
- `Cmd+R` para compilar y correr
- Para archivar: `Product → Archive`

---

## 2. Android Nativa (Kotlin + Jetpack Compose) — `Procesamiento-Android/`

**Requisitos:** Android Studio Ladybug+ / JDK 11+

```bash
cd Procesamiento-Android
# Abrir con Android Studio o compilar desde línea de comandos:
./gradlew assembleDebug                  # APK debug
./gradlew assembleRelease                # APK release (requiere keystore)
./gradlew installDebug                   # Instalar en dispositivo conectado
```

El APK queda en: `app/build/outputs/apk/debug/app-debug.apk`

---

## 3. React Native — `Procesamiento-ReactNative/`

**Requisitos:** Node 18+, npx react-native CLI, Xcode (iOS), Android Studio (Android)

```bash
cd Procesamiento-ReactNative
npm install

# iOS
npx react-native run-ios
# Build release iOS
npx react-native build-ios --mode Release

# Android
npx react-native run-android
# Build release Android
cd android && ./gradlew assembleRelease
```

> **Nota:** El archivo `quijote.txt` debe registrarse en Metro como asset de texto. Está configurado en `metro.config.js`. Para cargarlo en la app se usa `require('./quijote.txt')` — Metro lo incrusta en el bundle.

---

## 4. .NET MAUI — `Procesamiento-MAUI/Procesamiento/`

**Requisitos:** .NET 9 SDK + MAUI workload

```bash
# Instalar workload MAUI (primera vez)
dotnet workload install maui

cd Procesamiento-MAUI/Procesamiento

# iOS (requiere macOS + Xcode)
dotnet build -f net9.0-ios -c Release
dotnet publish -f net9.0-ios -c Release

# Android
dotnet build -f net9.0-android -c Release
dotnet publish -f net9.0-android -c Release
# APK en: bin/Release/net9.0-android/publish/
```

---

## 5. Flutter — `Procesamiento-Flutter/`

**Requisitos:** Flutter SDK 3.22+ con Dart 3.4+

```bash
cd Procesamiento-Flutter
flutter pub get

# iOS (requiere macOS + Xcode)
flutter build ios --release
flutter run --release  # en simulador/dispositivo

# Android
flutter build apk --release
flutter build appbundle --release   # .aab para Google Play
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

---

## Funcionalidades de todas las apps

| Característica | Detalle |
|---|---|
| Conteo de palabras | Tokenización lingüística |
| Conteo de oraciones | Detección por `.` `!` `?` |
| Conteo de párrafos | Separación por líneas vacías |
| Frecuencia por palabra | Ranking completo ordenado |
| Tiempo de procesamiento | Medición precisa en ms/s |
| Gráfico Top 10 | Barras proporcionales |
| Modal scrollable | Lista completa con búsqueda |
| UI dark mode | Tema oscuro moderno |

---

## Estructura de carpetas

```
don-quijote/
├── el quijote  de la mancha.txt     ← Texto original
├── Procesamiento-iOS/               ← SwiftUI (Xcode)
│   ├── Procesamiento.xcodeproj/
│   └── Procesamiento/
│       ├── ProcesamientoApp.swift
│       ├── ContentView.swift
│       ├── ProcessingEngine.swift
│       └── quijote.txt
├── Procesamiento-Android/           ← Kotlin + Compose
│   ├── app/src/main/
│   │   ├── java/com/procesamiento/app/
│   │   └── assets/quijote.txt
│   └── build.gradle.kts
├── Procesamiento-ReactNative/       ← React Native
│   ├── App.tsx
│   ├── src/ProcessingEngine.ts
│   └── quijote.txt
├── Procesamiento-MAUI/              ← .NET MAUI
│   └── Procesamiento/
│       ├── MainPage.xaml
│       ├── MainPage.xaml.cs
│       ├── ProcessingEngine.cs
│       └── Resources/Raw/quijote.txt
└── Procesamiento-Flutter/           ← Flutter / Dart
    ├── lib/
    │   ├── main.dart
    │   └── processing_engine.dart
    └── assets/quijote.txt
```
