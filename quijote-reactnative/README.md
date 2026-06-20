# quijote reac

Aplicacion React Native para procesar el texto de `quijote.txt` y mostrar estadisticas como cantidad de palabras, oraciones, parrafos y frecuencia de palabras.

El nombre visible de la app es `quijote reac`. Internamente el proyecto nativo se llama `Procesamiento`, por eso veras ese nombre en algunos comandos de iOS, schemes y carpetas.

## Requisitos

- macOS con Xcode instalado para iOS.
- Android Studio y Android SDK para Android.
- Node.js 20 recomendado mediante `nvm`.
- CocoaPods para iOS.
- `cmake` para CocoaPods/Hermes en iOS.
- `ios-deploy` si quieres instalar en un iPhone fisico.

Versiones del proyecto:

- React Native `0.76.5`
- React `18.3.1`
- Android SDK compile `35`
- Android NDK `26.2.11394342`
- Android application id: `com.procesamiento`
- iOS scheme: `Procesamiento`

## Preparar Node

Usa Node 20. Evita el Node de Homebrew si da errores de librerias como `llhttp`.

```bash
nvm install 20
nvm use 20
node -v
which node
```

`which node` deberia apuntar a algo como:

```bash
/Users/seba/.nvm/versions/node/v20.x.x/bin/node
```

Para dejar Node 20 por defecto:

```bash
nvm alias default 20
```

## Instalar dependencias JS

Desde la raiz del proyecto:

```bash
npm install
```

Si ves errores de engine, confirma que estas usando Node 20:

```bash
nvm use 20
```

## Metro

Metro es el servidor que entrega el bundle JavaScript en modo desarrollo.

Ejecutalo en una terminal y dejalo abierto:

```bash
npm start -- --reset-cache
```

En otra terminal ejecutas iOS o Android.

Importante: para desarrollo normal no uses `--no-packager` si no tienes Metro abierto. Si la app muestra:

```text
No script URL provided
```

significa que la app se abrio sin Metro o sin bundle JS embebido.

## Texto `quijote.txt`

El proyecto incluye una configuracion especial para importar archivos `.txt` como string:

- `metro.config.js`
- `metro.txt-transformer.js`

Esto permite que `App.tsx` haga:

```ts
const quijoteText = require('./quijote.txt');
```

Si modificas esa configuracion, reinicia Metro con cache limpia:

```bash
npm start -- --reset-cache
```

## iOS: instalar Pods

La primera vez, instala pods:

```bash
cd ios
pod install
cd ..
```

Si CocoaPods falla por Hermes o CMake, instala:

```bash
brew install cmake
```

Si vas a instalar en iPhone fisico:

```bash
brew install ios-deploy
```

## iOS: ejecutar en simulador

1. Levanta Metro:

```bash
npm start -- --reset-cache
```

2. En otra terminal ejecuta:

```bash
npx react-native run-ios --simulator "iPhone 17"
```

Puedes ver simuladores disponibles con:

```bash
xcrun simctl list devices
```

Si hay varios destinos o un iPhone fisico conectado, especifica siempre el simulador para evitar que Xcode intente compilar para el dispositivo fisico:

```bash
npx react-native run-ios --simulator "iPhone 17"
```

## iOS: ejecutar en iPhone fisico

1. Conecta el iPhone por cable.
2. Abre el workspace:

```bash
open ios/Procesamiento.xcworkspace
```

3. En Xcode selecciona el target `Procesamiento`.
4. Configura `Signing & Capabilities` con tu Team.
5. Selecciona tu iPhone como destino y presiona Run.

Tambien puedes intentar por terminal:

```bash
npx react-native run-ios --device "Nombre del iPhone"
```

Si falla por firma o provisioning, termina de configurar el signing desde Xcode.

## Android: configurar SDK

Este proyecto espera el Android SDK en:

```properties
sdk.dir=/Users/seba/Library/Android/sdk
```

Ese valor esta en:

```text
android/local.properties
```

Si otra persona clona el proyecto, debe crear su propio `android/local.properties` con la ruta local de su SDK.

Ejemplo comun en macOS:

```properties
sdk.dir=/Users/TU_USUARIO/Library/Android/sdk
```

El NDK configurado en `android/build.gradle` es:

```gradle
ndkVersion = "26.2.11394342"
```

Se usa esa version porque NDK 28 puede romper la compilacion C++ de React Native 0.76/Folly con errores como:

```text
implicit instantiation of undefined template 'std::char_traits<unsigned char>'
```

## Android: ejecutar en emulador

1. Levanta Metro:

```bash
npm start -- --reset-cache
```

2. Abre un emulador desde Android Studio, o por terminal:

```bash
/Users/seba/Library/Android/sdk/emulator/emulator -avd Pixel_9a
```

3. Confirma que ADB lo ve:

```bash
adb devices
```

Debe aparecer algo como:

```text
emulator-5554    device
```

4. Ejecuta:

```bash
npx react-native run-android --no-packager
```

Usamos `--no-packager` porque Metro ya esta abierto en otra terminal. Si prefieres que React Native intente iniciar Metro por ti, puedes usar:

```bash
npx react-native run-android
```

Si aparece:

```text
No connected devices!
```

significa que ADB no ve ningun emulador o dispositivo. Revisa:

```bash
adb devices
```

## Android: ejecutar en dispositivo fisico

1. En el telefono Android activa:
   - Developer options
   - USB debugging

2. Conecta el dispositivo por USB.

3. Acepta el permiso RSA en el telefono.

4. Verifica:

```bash
adb devices
```

Debe aparecer como `device`, no como `unauthorized`.

5. Ejecuta:

```bash
npx react-native run-android --no-packager
```

Si aparece `unauthorized`, desconecta y conecta el cable, acepta el permiso en el telefono y vuelve a correr:

```bash
adb devices
```

## Build Android Debug

Para generar un APK debug:

```bash
cd android
./gradlew assembleDebug
cd ..
```

Salida:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

Para instalarlo manualmente:

```bash
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

## Build Android Release

El script actual ejecuta:

```bash
npm run build:android
```

Equivale a:

```bash
cd android
./gradlew assembleRelease
cd ..
```

Salida esperada:

```text
android/app/build/outputs/apk/release/app-release.apk
```

Nota importante: ahora el release usa la `debug.keystore` de la plantilla. Eso sirve para pruebas locales, pero no para publicar en Play Store.

Para un release real debes crear un keystore propio y configurar `signingConfigs.release` en `android/app/build.gradle`.

Ejemplo de generacion de keystore:

```bash
keytool -genkeypair -v \
  -storetype PKCS12 \
  -keystore android/app/quijote-release-key.keystore \
  -alias quijote-release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Luego configura credenciales de firma de forma segura, idealmente con variables o `gradle.properties`, no hardcodeadas en git.

## Android App Bundle para Play Store

Para generar un `.aab`:

```bash
cd android
./gradlew bundleRelease
cd ..
```

Salida:

```text
android/app/build/outputs/bundle/release/app-release.aab
```

## Build iOS Debug

Normalmente se usa Xcode o:

```bash
npx react-native run-ios --simulator "iPhone 17"
```

Para compilar sin instalar:

```bash
xcodebuild \
  -workspace ios/Procesamiento.xcworkspace \
  -scheme Procesamiento \
  -configuration Debug \
  -sdk iphonesimulator
```

## Build iOS Release

El script actual es:

```bash
npm run build:ios
```

Equivale a:

```bash
xcodebuild \
  -workspace ios/Procesamiento.xcworkspace \
  -scheme Procesamiento \
  -configuration Release \
  -archivePath ios/Procesamiento.xcarchive \
  archive
```

Para distribuir o subir a App Store necesitas configurar signing en Xcode:

1. Abrir:

```bash
open ios/Procesamiento.xcworkspace
```

2. Seleccionar target `Procesamiento`.
3. Ir a `Signing & Capabilities`.
4. Configurar Team y Bundle Identifier.
5. Crear Archive desde Xcode:
   - Product -> Archive

## Comandos utiles

Ver dispositivos Android:

```bash
adb devices
```

Arrancar emulador Android:

```bash
/Users/seba/Library/Android/sdk/emulator/emulator -avd Pixel_9a
```

Ver simuladores iOS:

```bash
xcrun simctl list devices
```

Limpiar build Android:

```bash
cd android
./gradlew clean
cd ..
```

Reinstalar Pods:

```bash
cd ios
pod install
cd ..
```

Reiniciar Metro con cache limpia:

```bash
npm start -- --reset-cache
```

## Problemas conocidos

### `No connected devices!`

Android no ve ningun emulador/dispositivo.

Solucion:

```bash
adb devices
/Users/seba/Library/Android/sdk/emulator/emulator -avd Pixel_9a
adb wait-for-device
npx react-native run-android --no-packager
```

### `No script URL provided`

iOS abrio la app sin Metro.

Solucion:

```bash
npm start -- --reset-cache
npx react-native run-ios --simulator "iPhone 17"
```

### Error con Node de Homebrew y `llhttp`

Usa Node desde `nvm`:

```bash
nvm use 20
which node
```

### Error Android `SDK location not found`

Crea o corrige:

```text
android/local.properties
```

Con:

```properties
sdk.dir=/Users/seba/Library/Android/sdk
```

### Error C++ con NDK 28

Usa NDK `26.2.11394342` en `android/build.gradle`:

```gradle
ndkVersion = "26.2.11394342"
```

## Estructura principal

```text
App.tsx                         UI principal
src/ProcessingEngine.ts          Logica de procesamiento del texto
quijote.txt                      Texto fuente
metro.config.js                  Configuracion Metro
metro.txt-transformer.js         Transformer para importar .txt como string
android/                         Proyecto Android nativo
ios/                             Proyecto iOS nativo
```
