# Capeonn Multi-Platform Client Production Release Guide

This document details the complete end-to-end instructions for packaging, signing, optimizing, and releasing the `capeonn_app` Flutter client across Android, iOS, Web (PWA), and Windows Desktop.

---

## 1. Android Release (Google Play & APK Direct)

### 1.1 Generating a Production Keystore
Generate a PKCS12 keystore using `keytool`:
```bash
keytool -genkey -v -keystore capeonn-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias capeonn-release
```
Place `capeonn-release-key.jks` into `capeonn_app/android/app/` (or a secure CI/CD vault). **Never commit the `.jks` file to Git.**

### 1.2 Configuring `key.properties`
Create `capeonn_app/android/key.properties`:
```properties
storePassword=YOUR_SECURE_STORE_PASSWORD
keyPassword=YOUR_SECURE_KEY_PASSWORD
keyAlias=capeonn-release
storeFile=capeonn-release-key.jks
```
Verify that `key.properties` is listed in `capeonn_app/.gitignore`.

### 1.3 Code Obfuscation & ProGuard Rules
Verify `capeonn_app/android/app/build.gradle` has release signing enabled with code shrinkage and resource optimization:
```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 1.4 Building Artifacts
Build Google Play App Bundle (`.aab`):
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/android-symbols/
```
The output is located at:
`build/app/outputs/bundle/release/app-release.aab`

For sideloaded enterprise distribution, build a split APK:
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/android-symbols/
```
Outputs:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
`build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
`build/app/outputs/flutter-apk/app-x86_64-release.apk`

---

## 2. iOS Release (App Store & TestFlight)

### 2.1 Apple Developer Portal Prerequisites
1. Register App ID: `com.capeonn.app` with Push Notifications and Associated Domains enabled.
2. Generate an **Apple Distribution Certificate** and install it into macOS Keychain.
3. Generate a **Provisioning Profile (App Store)** for `com.capeonn.app`.

### 2.2 Xcode Signing Configuration
Open `ios/Runner.xcworkspace` in Xcode:
1. Select the **Runner** target -> **Signing & Capabilities**.
2. Select Team: **Capeonn Technologies Inc.**
3. Signing Certificate: `Apple Distribution`.
4. Bundle Identifier: `com.capeonn.app`.

### 2.3 Building the iOS Archive & IPA
Run the Flutter build command on macOS:
```bash
flutter build ipa --release --obfuscate --split-debug-info=build/ios-symbols/ --export-options-plist=ios/ExportOptions.plist
```
Upload directly to TestFlight via Xcode or `xcrun altool`:
```bash
xcrun altool --upload-app --type ios --file "build/ios/ipa/capeonn_app.ipa" --username "developer@capeonn.com" --password "@keychain:ALTOOL_PASSWORD"
```

---

## 3. Web Release (Progressive Web App - PWA)

### 3.1 PWA Manifest & Icons
The web app is configured with `web/manifest.json` featuring:
- `short_name`: `Capeonn`
- `name`: `Capeonn Workplace Suite`
- `theme_color`: `#1E3A8A`
- `background_color`: `#0F172A`
- `display`: `standalone`
- Web workers and service worker caching for offline asset loading.

### 3.2 Building Optimized Web Bundle
Compile with CanvasKit / Auto renderer and aggressive HTML minification:
```bash
flutter build web --release --pwa-strategy=offline-first --web-renderer canvaskit
```
The production bundle will be generated at `build/web/`.

### 3.3 Production Web Hosting (Nginx SPA)
To host the Web application on Nginx with HTTP/2 and Brotli/Gzip compression:
```nginx
server {
    listen 443 ssl http2;
    server_name app.capeonn.com;

    root /var/www/capeonn/capeonn_app/build/web;
    index index.html;

    ssl_certificate /etc/letsencrypt/live/app.capeonn.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.capeonn.com/privkey.pem;

    # Caching for immutable Flutter assets
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Ensure Flutter router handles client-side routes (SPA fallback)
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```

---

## 4. Windows Desktop Release (MSIX & Portable EXE)

### 4.1 Prerequisites
- Windows 10/11 with Visual Studio 2022 (C++ Desktop development workload).
- Flutter desktop support enabled (`flutter config --enable-windows-desktop`).

### 4.2 Building Windows Release
Compile optimized native x64 Windows binaries:
```bash
flutter build windows --release --obfuscate --split-debug-info=build/windows-symbols/
```
The output directory is located at:
`build/windows/x64/runner/Release/`

Included executable and dynamic libraries:
- `capeonn_app.exe`
- `flutter_windows.dll`
- Plugins `.dll` files
- `data/` asset bundles and ICU data

### 4.3 MSIX Packaging
Using the `msix` Flutter package:
```bash
dart run msix:create --publisher-display-name="Capeonn Corp" --identity-name="Capeonn.WorkplaceSuite" --signtool-options="/v /s MY /n Capeonn"
```
Output:
`build/windows/x64/runner/Release/capeonn_app.msix`

---

## 5. Automated Build Matrix Script

Use the included orchestration scripts to automate builds:
- Windows / PowerShell: `scripts/build_all_releases.ps1`
- Linux / macOS / CI: `scripts/build_all_releases.sh`

Both scripts support target filtering:
```powershell
# Build only Web and Android
.\scripts\build_all_releases.ps1 -Targets "web","android"

# Full production matrix with obfuscation
.\scripts\build_all_releases.ps1 -Targets "all"
```
