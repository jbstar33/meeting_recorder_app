# Flutter Bootstrap Checklist

## 1. Create Project

```powershell
flutter create voicenote_ai
```

Recommended package id:

- Android: `com.onestore.voicenote_ai`
- iOS bundle id: `com.onestore.voicenoteAi`

---

## 2. Add Core Dependencies

Add these first:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  go_router: ^14.8.1
  flutter_secure_storage: ^9.2.2
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  path_provider: ^2.1.5
  permission_handler: ^11.4.0
  record: ^6.0.0
  just_audio: ^0.9.46
  flutter_local_notifications: ^18.0.1
  share_plus: ^10.1.4
  flutter_markdown: ^0.7.6+2
  intl: ^0.20.2
  uuid: ^4.5.1
  crypto: ^3.0.6
  collection: ^1.19.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.15
  isar_generator: ^3.1.0+1
  flutter_lints: ^5.0.0
```

Optional later:

- `local_auth`
- `dio`
- `connectivity_plus`
- `file_picker`

---

## 3. Android Configuration

Check these before coding:

- minSdkVersion: `26`
- microphone permission
- foreground service permission
- notification permission for Android 13+
- internet permission only if cloud features are enabled

---

## 4. First Folder Setup

Create these folders first:

```text
lib/
  core/
    constants/
    theme/
    utils/
  router/
  data/
    models/
    repositories/
    sources/
  services/
    audio/
    stt/
    analysis/
    export/
    security/
  presentation/
    screens/
      auth/
      home/
      recording/
      transcript/
      settings/
    widgets/
    providers/
```

---

## 5. First Screens To Implement

Build in this order:

1. splash/bootstrap gate
2. PIN setup screen
3. PIN unlock screen
4. home screen
5. recording screen
6. transcript detail screen
7. settings screen

---

## 6. Mock-First Services

Create interfaces first:

- `AudioRecorderService`
- `SttService`
- `AnalysisService`
- `ExportService`
- `PinService`

Use mock or placeholder implementations for:

- `SttService`
- `AnalysisService`

This keeps the first app build stable while native and cloud engines are still pending.

---

## 7. Definition Of Ready For Full App Generation

We are ready to generate the actual app when these are fixed:

- project name
- package id
- dependency set
- initial folder architecture
- MVP scope
- mock-first strategy for AI engines

Current status:

- MVP scope: ready
- architecture: ready
- bootstrap package list: ready
- native engine plan: deferred by design
