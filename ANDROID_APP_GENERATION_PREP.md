# Android App Generation Prep

## 1. Goal

`ANDROID_APP_SPEC.md` is detailed enough to define the product direction, but it is still too large and risky to use as a direct "generate the whole app" input.

This preparation doc converts the spec into:

- a realistic MVP boundary
- concrete technical decisions for the first build
- a recommended Flutter project structure
- an implementation order that reduces rework
- a risk list for native on-device AI integration

---

## 2. Product Summary

Target app:

- Privacy-first meeting recorder
- Android-first, iOS-ready Flutter app
- PIN-protected local storage
- Offline recording and transcript management
- On-device STT, diarization, and AI analysis as the long-term direction
- Optional cloud fallback with user-provided API keys

Core user flow:

1. Unlock app with PIN
2. Start recording
3. Stop and save recording
4. Run transcription
5. Review transcript by speaker
6. Run summary/action item analysis
7. Export/share results

---

## 3. Recommended Delivery Scope

## Phase 1: Foundation MVP

Build first:

- Flutter app shell
- Soft-blue design system
- PIN setup / unlock flow
- Recording list screen
- Start / pause / resume / stop recording
- Local metadata storage
- Recording detail screen
- Transcript model and viewer UI
- Manual "processing pipeline" status handling
- Settings screens with local persistence
- Export/share for local files

Use temporary implementations for:

- local STT
- diarization
- local LLM analysis

Why:

- The biggest technical risk is native ML runtime integration, not Flutter UI.
- We should stabilize app architecture, data models, storage, and recording lifecycle first.
- Once the app shell is stable, native engines can be integrated behind interfaces without rewriting screens.

## Phase 2: Practical Usable Release

Add next:

- OpenAI STT integration
- OpenAI analysis integration
- transcript JSON/Markdown generation
- search, filter, sort
- bookmarks
- basic background processing UX

Why:

- This provides an end-to-end useful version before local ML is production-ready.

## Phase 3: Offline Intelligence

Add after that:

- whisper.cpp FFI integration
- sherpa-onnx diarization integration
- llama.cpp FFI integration
- model download / import manager
- runtime performance optimization

---

## 4. Key Technical Decisions

Recommended choices for v1 foundation:

- Framework: Flutter
- Language: Dart
- State management: `flutter_riverpod`
- Routing: `go_router`
- Database: `isar`
- Secure storage: `flutter_secure_storage`
- Recording: `record`
- Audio playback: `just_audio`
- Sharing/export: `share_plus`
- Permissions: `permission_handler`
- Local notifications: `flutter_local_notifications`
- Serialization: plain Dart models first, codegen only if needed

Reasoning:

- Riverpod fits layered architecture and async workflows well.
- Isar is a better fit than Hive for query-heavy features like search/filter/history.
- The spec already anticipates service abstraction, so engine-specific integrations should remain behind interfaces.

---

## 5. Architecture Translation

Recommended app layers:

### Presentation

- screens
- widgets
- providers / controllers
- router

### Domain-ish Application Layer

- use cases
- workflow coordinators
- service interfaces

### Data

- repositories
- local database adapters
- secure storage adapters
- file storage adapters

### Platform / Engine

- audio recording adapter
- cloud STT adapter
- cloud analysis adapter
- native FFI bindings for whisper / llama / sherpa

Important rule:

- UI must never call FFI or raw storage directly.
- All heavy operations should go through services and repositories.

---

## 6. Suggested Initial Project Structure

Use this as the starting scaffold:

```text
voicenote_ai/
  lib/
    app.dart
    main.dart
    core/
      constants/
      theme/
      utils/
    router/
      app_router.dart
    data/
      models/
      repositories/
      sources/
    services/
      audio/
      stt/
      diarization/
      analysis/
      export/
      security/
    presentation/
      screens/
        auth/
        home/
        recording/
        transcript/
        analysis/
        settings/
      widgets/
      providers/
  assets/
    icons/
    fonts/
    models/
  test/
    unit/
    widget/
    integration/
```

Adjustment from original spec:

- Start with `presentation/screens/auth` instead of separate `pin/` naming to leave room for biometrics and session lock later.
- Keep `ffi/` out of the first scaffold if native bindings are not implemented yet.
- Add engine folders only when a real integration lands.

---

## 7. MVP Feature Cut Recommendations

Recommended to include:

- PIN lock
- recording lifecycle
- recording history list
- local storage
- transcript viewer
- settings persistence
- local export/share
- cloud STT/analysis as optional adapters

Recommended to defer:

- fully offline STT on first iteration
- speaker diarization on-device
- local LLM analysis
- model downloads
- biometric unlock
- real-time transcription
- cloud drive sync
- PDF export
- advanced search filters

This keeps the first generated app buildable and testable.

---

## 8. High-Risk Areas

### 8.1 Native ML Packaging

The spec assumes `whisper.cpp`, `llama.cpp`, and `sherpa-onnx` can be packaged cleanly into Flutter for Android.

Risks:

- ABI-specific `.so` management
- APK/AAB size growth
- memory spikes on mid-range devices
- background execution limits
- FFI crash/debug complexity

### 8.2 Performance Expectations

Some targets are aggressive for mid-range Android devices, especially:

- whisper small under 90 seconds per minute audio
- local 3B LLM inference under 60 seconds
- memory under 3.5 GB during local analysis

These should be treated as optimization targets, not assumptions for the first generated version.

### 8.3 Diarization Quality

Speaker diarization on-device is likely the least stable part of the stack. It should remain optional behind a feature flag until validated on representative Korean meeting audio.

---

## 9. Recommended Build Sequence

### Step 1. Bootstrap project

- create Flutter app
- add package dependencies
- set Android min SDK / permissions
- add app theme and routing

### Step 2. Security shell

- implement first-launch PIN setup
- implement unlock flow
- store hashed PIN in secure storage
- add session lock state

### Step 3. Recording pipeline

- microphone permission flow
- record / pause / resume / stop
- file naming and storage rules
- recording list + detail page

### Step 4. Persistence

- Isar schemas
- repositories
- recording status transitions
- settings storage

### Step 5. Transcript workflow

- transcript model
- placeholder processing service
- transcript detail screen
- edit transcript segment text

### Step 6. Cloud adapters

- OpenAI STT service
- OpenAI analysis service
- encrypted API key storage

### Step 7. Export and share

- Markdown / JSON export
- share sheet

### Step 8. Native offline engines

- whisper.cpp
- sherpa-onnx
- llama.cpp

---

## 10. Recommended Status Model

Use a single workflow enum for recordings:

```dart
enum RecordingWorkflowStatus {
  idle,
  recording,
  paused,
  saved,
  queuedForTranscription,
  transcribing,
  transcribed,
  analyzing,
  analyzed,
  failed,
}
```

Why:

- simpler UI rendering
- simpler filtering
- easier background job recovery

The spec's original status list is usable, but this version is slightly easier for controller logic.

---

## 11. Generation-Ready Constraints

When generating the actual Flutter app, keep these constraints:

- Android first
- minimum SDK 26
- Riverpod + GoRouter + Isar
- clean architecture without overengineering
- mock local AI services first
- cloud services hidden behind interfaces
- no hard dependency on internet for core recording flow
- Korean-first UX copy, English-ready localization structure

---

## 12. Suggested First Code Generation Prompt

Use this when starting actual app creation:

> Create a Flutter Android-first app named `voicenote_ai` for privacy-first meeting recording. Use Riverpod, GoRouter, Isar, flutter_secure_storage, record, just_audio, permission_handler, share_plus, and flutter_local_notifications. Implement a polished soft-blue design system, first-launch PIN setup, unlock screen, home screen with recording list, recording screen with start/pause/resume/stop, local metadata persistence, settings screen, and transcript detail screen with placeholder transcript data. Structure the code with presentation/data/services/router/core layers and keep STT/analysis behind interfaces so whisper.cpp and llama.cpp can be integrated later.

---

## 13. Immediate Next Deliverables

The next practical artifacts to generate are:

1. Flutter project scaffold
2. `pubspec.yaml` dependency setup
3. app theme system
4. router + shell screens
5. PIN flow
6. recording domain model + repository
7. recording UI

---

## 14. Recommendation

Do not attempt full spec generation in one pass.

Best path:

- generate a strong Flutter shell first
- prove recording/storage/security UX
- add cloud adapters
- then integrate offline native AI incrementally

That order gives us a working app early and avoids major architectural resets.
