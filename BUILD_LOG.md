# Pencraft — Build Log
**App:** invoice-maker | **Package:** com.isaac.pencraft | **Started:** 2026-11-01

---

## Log Format
`YYYY-MM-DD HH:MM | phase/milestone | status | decisions & defaults | open issues | next step`

---

## 2026-11-01 10:49 | Phase 0 — Environment | IN PROGRESS | Package prefix: com.isaac; App name: Pencraft (Folio/Tally/Ledgr all conflict on Play Store; Pencraft clear); Package: com.isaac.pencraft | JDK 17, Flutter 3.47.9, Android cmdline-tools all downloading in parallel | Confirm installs, set PATH, confirm phone via adb devices

## 2026-11-01 12:00 | Phase 0 — Environment | IN PROGRESS — MAJOR PROGRESS |
- ✅ JDK 17 (Azul Zulu 17.0.21) installed at C:\Program Files\Zulu\zulu-17; JAVA_HOME set
- ✅ Android cmdline-tools 16.0 extracted to C:\android-sdk\cmdline-tools\latest
- ✅ Android SDK licenses accepted via sdkmanager --no_https
- ✅ platform-tools 37.0.1 installed (adb.exe working)
- ✅ build-tools;35.0.0 installed
- ✅ platforms;android-35 installed
- ✅ Phone detected: itel A666L (11261193CK017104) — awaiting USB auth on device
- ⏳ Flutter 3.47.9 downloading via BITS: ~63% of 1.85 GB — BITS job survives restarts
- ⏳ Phone USB debugging not yet authorized (user needs to tap Allow on device)
| All imports fixed; database.dart, all services, all widgets in app/lib | Server restarted 3x during downloads | Flutter install; flutter create; flutter pub get; build_runner; flutter run

## 2026-11-01 10:54 | Phase 1 — Research & SPEC | DONE | SPEC.md written; research from 4 reference apps incorporated; naming conflict check complete; design palette, data model, flows, monetization all documented | Play Store name "Pencraft" still needs final verification | Begin _template once Flutter is installed

---

## Decisions & Defaults Log

| Decision | Default | Why |
|----------|---------|-----|
| App name | Pencraft | Folio, Tally, Ledgr all have Play Store conflicts in invoice space |
| Package ID | com.isaac.pencraft | PACKAGE_PREFIX=com.isaac + brand slug |
| Flutter version | 3.47.9 stable | Latest stable as of 2026-11-01 |
| JDK | Azul Zulu 17 | Flutter/Gradle requires JDK 17; AS JBR is Java 25 (incompatible) |
| Android SDK | API 35 (Android 15) | Latest stable; minSdk 21 covers 99%+ of active devices |
| Primary accent | #C0392B (sealing wax red) | Not fintech blue/purple; warm, confident, stamp-like |
| Money storage | Integer minor units | Never floating point (avoids rounding bugs) |
| PDF library | dart:pdf + printing | Pure Dart, no native deps |
| Charts | Custom CustomPainter | No fl_chart dependency; simpler, faster |
| Icon set | Phosphor Icons | Consistent weight, humanist style, MIT license |
| Default currency | KES | East Africa / Kenya focus per brief |
| Default VAT | 16% | Kenya standard VAT rate |

---

## Phase Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 0 — Environment | ✅ Done | JDK17+Flutter3.47.9+Android SDK 35+36; ENVIRONMENT.txt written |
| Phase 1 — Research & SPEC | ✅ Done | SPEC.md written |
| M1 — Skeleton & Data | ✅ Done | App running on itel A666L; seed data loads; 4 tabs visible |
| M2 — Core Lifecycle | ✅ Done | PDF built; WhatsApp share wired; payment recording written; APK installs |
| M3 — Onboarding & Monetization | 🔄 In Progress | |
| M4 — Polish & Release | ⏳ Pending | |

---

## 2026-11-01 13:30 | M1+M2 — Code complete, analyze clean | DONE |
- ✅ flutter analyze: 0 errors, 0 warnings (only prefer_const_constructors info)
- ✅ Unit tests: 33/33 passed (InvoiceMath, DocumentNumbering, CurrencyFormatter)
- ✅ ENVIRONMENT.txt written to C:\AppDevelopment\
- ✅ Fixes applied: seed_data PaymentsCompanion (Value→plain int + createdAt), _buildPreviewDoc() added, pdf_service dart:io import, unused imports cleaned
- ⏳ flutter run launched on itel A666L — awaiting first build

## 2026-11-01 16:13 | M1+M2 — FIRST SUCCESSFUL RUN | DONE |
- ✅ flutter run succeeded on itel A666L (11261193CK017104)
- ✅ APK built: build\app\outputs\flutter-apk\app-debug.apk
- ✅ Installed and running: com.isaac.pencraft PID 15586
- ✅ Flutter engine rendering (FlutterJNI viewport metrics sent)
- ✅ Google Mobile Ads SDK initialized (test device ID: 36D64DC980A1AC0468702A89B096093F)
- ✅ Git init + commit: "M1+M2: Pencraft skeleton, Drift schema, seed data, all screens, PDF service, WhatsApp share"
- Build stack: Gradle 8.14.1 + AGP 8.11.1 + Kotlin 2.2.20 + JDK 17 + Android SDK 34/35
- Auto-installed during build: Android SDK Platform 34, CMake 3.22.1
- Next: M3 — Onboarding wizard DB save, paywall enforcement, RevenueCat MOCK, backup screen wire-up

## 2026-11-01 16:34 | M4 — Polish & Release | IN PROGRESS |
- ✅ Launcher icons generated (mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi + round) — "P" lettermark, sealing-wax red circle on warm white
- ✅ Splash screen — warm paper #FAF7F2 background + centered icon
- ✅ R8 minification enabled in build.gradle.kts (release builds)
- ✅ proguard-rules.pro created
- ✅ PRIVACY_POLICY.md written
- ✅ SIGNING.md written (commands only, no keystore created)
- ✅ version: 1.0.0+1 already set in pubspec.yaml
- 🔄 flutter build apk --release launching...
