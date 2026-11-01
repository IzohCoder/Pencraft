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
| M1 — Skeleton & Data | 🔄 In Progress | All screens written; seed data ready; flutter run launching now |
| M2 — Core Lifecycle | 🔄 In Progress | PDF service, WhatsApp service, payment recording all written; pending phone verification |
| M3 — Onboarding & Monetization | ⏳ Pending | |
| M4 — Polish & Release | ⏳ Pending | |

---

## 2026-11-01 13:30 | M1+M2 — Code complete, analyze clean | DONE |
- ✅ flutter analyze: 0 errors, 0 warnings (only prefer_const_constructors info)
- ✅ Unit tests: 33/33 passed (InvoiceMath, DocumentNumbering, CurrencyFormatter)
- ✅ ENVIRONMENT.txt written to C:\AppDevelopment\
- ✅ Fixes applied: seed_data PaymentsCompanion (Value→plain int + createdAt), _buildPreviewDoc() added, pdf_service dart:io import, unused imports cleaned
- ⏳ flutter run launched on itel A666L — awaiting first build
