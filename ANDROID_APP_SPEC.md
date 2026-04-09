# VoiceNote AI — Mobile Meeting Recorder & Analyzer

## Product Requirements Document (PRD)

> **Purpose**: This document is a complete, self-contained specification for building a cross-platform mobile application (Android-first, iOS-ready) that records meetings, transcribes speech-to-text locally, separates speakers, and analyzes/summarizes transcripts using on-device AI — all without requiring network connectivity by default.
>
> **Reference Implementation**: This app is a mobile adaptation of an existing Python CLI tool (`Record_analyzer`) that uses OpenAI Whisper for STT, pyannote for speaker diarization, and outputs structured JSON/Markdown transcripts. The mobile version must replicate and extend this functionality with a polished native experience.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Technology Stack](#2-technology-stack)
3. [Architecture](#3-architecture)
4. [Feature Specifications](#4-feature-specifications)
   - 4.1 [Security — PIN Lock](#41-security--pin-lock)
   - 4.2 [Audio Recording](#42-audio-recording)
   - 4.3 [Speech-to-Text (STT)](#43-speech-to-text-stt)
   - 4.4 [Speaker Diarization](#44-speaker-diarization)
   - 4.5 [AI Analysis & Summarization](#45-ai-analysis--summarization)
   - 4.6 [Transcript Output & Formatting](#46-transcript-output--formatting)
   - 4.7 [Storage & Export](#47-storage--export)
   - 4.8 [Recording Management](#48-recording-management)
   - 4.9 [Settings](#49-settings)
5. [UI/UX Design System](#5-uiux-design-system)
6. [Data Models](#6-data-models)
7. [File & Directory Structure](#7-file--directory-structure)
8. [Third-Party Dependencies](#8-third-party-dependencies)
9. [Build & Deployment](#9-build--deployment)
10. [Performance Requirements](#10-performance-requirements)
11. [Testing Strategy](#11-testing-strategy)
12. [Future Considerations](#12-future-considerations)

---

## 1. Overview

### 1.1 Product Vision

**VoiceNote AI** is a privacy-first mobile application for recording meetings and conversations, transcribing them to text with speaker identification, and generating AI-powered summaries — all running locally on-device without requiring internet connectivity.

### 1.2 Key Principles

| Principle | Description |
|-----------|-------------|
| **Privacy First** | All core processing (STT, diarization, analysis) runs on-device by default. No data leaves the device unless the user explicitly opts into external services. |
| **Offline Capable** | The app must be fully functional without network connectivity for recording, transcription, and basic analysis. |
| **Extensible** | Users who want higher accuracy or faster processing can opt into cloud APIs (OpenAI, Google, etc.) by providing their own API keys. |
| **Cross-Platform** | Built with Flutter for simultaneous Android and iOS support from a single codebase. |
| **Intuitive UX** | Minimal, clean interface with a soft blue color palette. One-tap recording, clear navigation. |

### 1.3 Target Users

- Professionals who attend frequent meetings and need accurate records
- Teams requiring meeting minutes with speaker attribution
- Users in privacy-sensitive environments (legal, medical, corporate)
- Korean-language primary users (with multilingual support)

---

## 2. Technology Stack

### 2.1 Framework Decision: Flutter

**Chosen Framework**: **Flutter** (Dart)

**Rationale**:

| Criterion | Flutter | React Native | Kotlin Multiplatform |
|-----------|---------|--------------|---------------------|
| iOS + Android from single codebase | Yes | Yes | Yes (UI layer varies) |
| Native performance | Compiled to ARM (excellent) | JS bridge (good) | Native (excellent) |
| On-device ML integration | FFI / Platform Channels | Native Modules (complex) | Direct native access |
| UI consistency across platforms | Pixel-perfect | Platform-dependent | Platform-dependent |
| Hot reload / dev speed | Excellent | Good | Moderate |
| Community + packages | Large | Largest | Growing |
| Custom UI design control | Full control (own rendering) | Limited by native components | Limited by native components |

Flutter is the optimal choice because:
1. **FFI (Foreign Function Interface)** enables direct C/C++ library calls (whisper.cpp, llama.cpp) without platform channel overhead
2. **Custom rendering engine** gives full control over the soft-blue design system
3. **Compiled performance** is critical for on-device ML inference
4. **Single codebase** for both Android and iOS with identical UX

### 2.2 Core Technology Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | Flutter 3.x (Dart) | Cross-platform UI and app logic |
| **Local STT** | whisper.cpp (via dart:ffi) | On-device speech-to-text using OpenAI Whisper models |
| **Local LLM** | llama.cpp (via dart:ffi) | On-device transcript analysis and summarization |
| **Speaker Diarization** | sherpa-onnx / pyannote ONNX export | On-device speaker separation |
| **Audio Recording** | Platform-native (MediaRecorder / AVAudioRecorder) | High-quality audio capture |
| **Local Database** | Isar or Hive | Structured data storage for recordings and transcripts |
| **State Management** | Riverpod or BLoC | Reactive state management |
| **Secure Storage** | flutter_secure_storage | PIN hash and API key storage |
| **File Compression** | FLAC encoder (native) | Lossless audio compression |

### 2.3 External API Integrations (Optional, User-Provided Keys)

| Service | Purpose | When Used |
|---------|---------|-----------|
| OpenAI Whisper API | Cloud-based STT with higher accuracy | User opts in via Settings |
| OpenAI GPT API | Cloud-based analysis/summarization | User opts in via Settings |
| Google Cloud STT | Alternative cloud STT | User opts in via Settings |
| Google Drive / Dropbox / iCloud | Cloud export destinations | User opts in via Settings |

---

## 3. Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        VoiceNote AI App                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │   PIN    │  │ Recording│  │Transcript│  │   Settings   │   │
│  │  Screen  │  │  Screen  │  │   List   │  │    Screen    │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       │              │              │               │           │
│  ─────┴──────────────┴──────────────┴───────────────┴──────     │
│                     Presentation Layer                          │
│            (Riverpod / BLoC State Management)                   │
│  ──────────────────────────────────────────────────────────     │
│                      Service Layer                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ Audio    │  │   STT    │  │Diarization│ │   Analysis   │   │
│  │ Service  │  │ Service  │  │  Service  │  │   Service    │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       │              │              │               │           │
│  ─────┴──────────────┴──────────────┴───────────────┴──────     │
│                      Engine Layer (FFI)                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ Native   │  │whisper.  │  │sherpa-   │  │  llama.cpp   │   │
│  │ Audio    │  │  cpp     │  │  onnx    │  │              │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│                                                                 │
│  ──────────────────────────────────────────────────────────     │
│                      Data Layer                                 │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Local Database  │  │  File System │  │Secure Storage│     │
│  │  (Isar / Hive)   │  │  (Audio/JSON)│  │ (PIN, Keys)  │     │
│  └──────────────────┘  └──────────────┘  └──────────────┘     │
│                                                                 │
│  ──────────────────────────────────────────────────────────     │
│                   External APIs (Optional)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ OpenAI   │  │ Google   │  │ Cloud    │  │   Other      │   │
│  │  API     │  │ STT API  │  │ Storage  │  │   APIs       │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Processing Pipeline

```
                    ┌─────────────┐
                    │  Microphone │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   Record    │  ← WAV 16kHz mono
                    │   Audio     │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Compress   │  ← Optional FLAC compression
                    │  (FLAC)     │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │                         │
       ┌──────▼──────┐          ┌──────▼──────┐
       │  Local STT  │          │  Cloud STT  │  ← User's API key
       │(whisper.cpp)│          │ (OpenAI API)│
       └──────┬──────┘          └──────┬──────┘
              │                         │
              └────────────┬────────────┘
                           │
                    ┌──────▼──────┐
                    │   Speaker   │  ← Optional
                    │ Diarization │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   Merge &   │  ← Assign speakers to text segments
                    │   Format    │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │                         │
       ┌──────▼──────┐          ┌──────▼──────┐
       │ Local LLM   │          │  Cloud LLM  │  ← User's API key
       │ (llama.cpp) │          │ (OpenAI GPT)│
       └──────┬──────┘          └──────┬──────┘
              │                         │
              └────────────┬────────────┘
                           │
                    ┌──────▼──────┐
                    │   Save &    │
                    │   Display   │  ← JSON + Markdown + DB
                    └─────────────┘
```

### 3.3 Directory / Module Structure

```
voicenote_ai/
├── android/                          # Android-specific native code
│   └── app/src/main/
│       ├── jniLibs/                  # Pre-built native libraries (.so)
│       │   ├── arm64-v8a/
│       │   │   ├── libwhisper.so
│       │   │   ├── libllama.so
│       │   │   └── libsherpa-onnx.so
│       │   └── armeabi-v7a/
│       └── kotlin/                   # Platform channel implementations
├── ios/                              # iOS-specific native code
│   └── Runner/
│       └── Frameworks/               # Pre-built native frameworks
├── lib/                              # Dart source code
│   ├── main.dart                     # App entry point
│   ├── app.dart                      # MaterialApp configuration
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart       # Color palette (soft blue)
│   │   │   ├── app_theme.dart        # ThemeData
│   │   │   └── app_typography.dart   # Text styles
│   │   ├── constants/
│   │   │   └── app_constants.dart    # App-wide constants
│   │   ├── utils/
│   │   │   ├── timestamp_utils.dart  # Time formatting helpers
│   │   │   ├── file_utils.dart       # File path helpers
│   │   │   └── audio_utils.dart      # Audio format helpers
│   │   └── di/
│   │       └── service_locator.dart  # Dependency injection setup
│   ├── data/
│   │   ├── models/
│   │   │   ├── recording.dart        # Recording data model
│   │   │   ├── transcript.dart       # Transcript data model
│   │   │   ├── segment.dart          # Transcript segment model
│   │   │   ├── analysis_result.dart  # Analysis result model
│   │   │   └── app_settings.dart     # Settings model
│   │   ├── repositories/
│   │   │   ├── recording_repository.dart
│   │   │   ├── transcript_repository.dart
│   │   │   └── settings_repository.dart
│   │   └── sources/
│   │       ├── local_database.dart   # Isar/Hive database
│   │       ├── file_storage.dart     # File system operations
│   │       └── secure_storage.dart   # Encrypted storage (PIN, keys)
│   ├── services/
│   │   ├── audio/
│   │   │   ├── audio_recorder_service.dart
│   │   │   ├── audio_player_service.dart
│   │   │   └── audio_compressor_service.dart
│   │   ├── stt/
│   │   │   ├── stt_service.dart              # Abstract STT interface
│   │   │   ├── whisper_local_service.dart     # whisper.cpp FFI binding
│   │   │   ├── openai_stt_service.dart        # OpenAI Whisper API
│   │   │   └── google_stt_service.dart        # Google Cloud STT API
│   │   ├── diarization/
│   │   │   ├── diarization_service.dart       # Abstract interface
│   │   │   ├── local_diarization_service.dart # sherpa-onnx
│   │   │   └── cloud_diarization_service.dart # External API fallback
│   │   ├── analysis/
│   │   │   ├── analysis_service.dart          # Abstract interface
│   │   │   ├── llama_local_service.dart       # llama.cpp FFI binding
│   │   │   ├── openai_analysis_service.dart   # OpenAI GPT API
│   │   │   └── prompt_templates.dart          # Analysis prompt templates
│   │   ├── export/
│   │   │   ├── export_service.dart            # Abstract interface
│   │   │   ├── local_export_service.dart      # Save to device storage
│   │   │   ├── cloud_export_service.dart      # Google Drive, Dropbox
│   │   │   └── share_service.dart             # OS share sheet
│   │   └── security/
│   │       └── pin_service.dart               # PIN management
│   ├── ffi/
│   │   ├── whisper_bindings.dart              # whisper.cpp FFI bindings
│   │   ├── llama_bindings.dart                # llama.cpp FFI bindings
│   │   └── sherpa_bindings.dart               # sherpa-onnx FFI bindings
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── pin/
│   │   │   │   ├── pin_screen.dart            # PIN entry UI
│   │   │   │   └── pin_setup_screen.dart      # First-time PIN setup
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart           # Main screen (recording list)
│   │   │   ├── recording/
│   │   │   │   └── recording_screen.dart      # Active recording UI
│   │   │   ├── transcript/
│   │   │   │   ├── transcript_detail_screen.dart
│   │   │   │   └── transcript_edit_screen.dart
│   │   │   ├── analysis/
│   │   │   │   └── analysis_screen.dart       # AI analysis results
│   │   │   ├── search/
│   │   │   │   └── search_screen.dart         # Full-text search
│   │   │   └── settings/
│   │   │       ├── settings_screen.dart
│   │   │       ├── stt_settings_screen.dart
│   │   │       ├── analysis_settings_screen.dart
│   │   │       ├── storage_settings_screen.dart
│   │   │       └── security_settings_screen.dart
│   │   ├── widgets/
│   │   │   ├── recording_card.dart
│   │   │   ├── waveform_visualizer.dart
│   │   │   ├── recording_controls.dart
│   │   │   ├── transcript_viewer.dart
│   │   │   ├── speaker_badge.dart
│   │   │   ├── pin_input_field.dart
│   │   │   ├── processing_indicator.dart
│   │   │   └── empty_state.dart
│   │   └── providers/
│   │       ├── recording_provider.dart
│   │       ├── transcript_provider.dart
│   │       ├── settings_provider.dart
│   │       └── auth_provider.dart
│   └── router/
│       └── app_router.dart                    # Navigation / routing
├── assets/
│   ├── models/                                # Bundled or downloadable models
│   │   └── .gitkeep
│   ├── icons/
│   └── fonts/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── pubspec.yaml
└── README.md
```

---

## 4. Feature Specifications

### 4.1 Security — PIN Lock

#### 4.1.1 Overview

The app must require a 4-digit PIN code on every launch to protect potentially sensitive meeting recordings and transcripts.

#### 4.1.2 First Launch — PIN Setup

- On first launch, display a "Welcome" screen explaining the app requires a PIN for security.
- Show a PIN setup screen where the user enters a 4-digit numeric PIN.
- Require confirmation: user must enter the same PIN twice.
- Store the PIN as a **bcrypt/SHA-256 hash** in `flutter_secure_storage` (never store plaintext).
- After setup, navigate to the Home screen.

#### 4.1.3 Subsequent Launches — PIN Entry

- On every app launch, display the PIN entry screen before any other content.
- Show 4 circular indicators that fill as digits are entered.
- Use a custom numeric keypad (not system keyboard) for consistent UX.
- After entering 4 digits, immediately validate against stored hash.
- **On success**: Animate indicators (brief check mark) and navigate to Home.
- **On failure**: Shake animation on indicators, clear input, increment attempt counter.
- **After 5 consecutive failures**: Lock the app for 30 seconds with a countdown timer.
- **After 10 consecutive failures**: Lock for 5 minutes.
- No "forgot PIN" flow in MVP (data is local-only; resetting PIN would require app data wipe).

#### 4.1.4 PIN Change

- Available in Settings > Security.
- Require current PIN before setting a new one.
- Same double-entry confirmation flow as setup.

#### 4.1.5 Biometric Unlock (Enhancement)

- If the device supports fingerprint or face recognition, offer biometric unlock as an alternative after PIN is set.
- PIN remains the fallback. Biometric is opt-in via Settings.

#### 4.1.6 Background / Resume Behavior

- When the app goes to background and returns after more than 30 seconds, require PIN re-entry.
- If the user switches away for less than 30 seconds, resume without PIN.
- The timeout threshold should be configurable in Settings (30s, 1min, 5min, never).

---

### 4.2 Audio Recording

#### 4.2.1 Overview

The core feature: high-quality audio recording optimized for speech recognition.

#### 4.2.2 Audio Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Sample Rate | 16,000 Hz | Optimal for Whisper |
| Channels | 1 (Mono) | Sufficient for speech; reduces file size |
| Bit Depth | 16-bit PCM | Standard for speech processing |
| Format (recording) | WAV | Uncompressed during recording |
| Format (storage) | FLAC | Lossless compression after recording (~50-70% size reduction) |
| Fallback format | WAV | If FLAC encoding is unavailable |

#### 4.2.3 Recording Screen UI

```
┌──────────────────────────────────┐
│  ← Back              VoiceNote  │
│                                  │
│                                  │
│         ┌──────────────┐         │
│         │  00:45:23    │         │  ← Large elapsed time display
│         └──────────────┘         │
│                                  │
│    ╭─────────────────────────╮   │
│    │  ▁▂▃▅▇▅▃▂▁▂▃▅▃▂▁▂▃▅▇  │   │  ← Real-time audio waveform
│    ╰─────────────────────────╯   │
│                                  │
│                                  │
│     ┌─────┐  ┌─────┐  ┌─────┐  │
│     │  ⏸  │  │  ⏹  │  │  🔖 │  │  ← Pause / Stop / Bookmark
│     └─────┘  └─────┘  └─────┘  │
│                                  │
│  "Tap Stop when finished"        │
└──────────────────────────────────┘
```

#### 4.2.4 Recording Controls

| Button | State | Action |
|--------|-------|--------|
| **Record** (on Home) | Idle | Start recording; navigate to Recording Screen |
| **Pause** | Recording | Pause audio capture; button becomes Resume |
| **Resume** | Paused | Resume audio capture; button becomes Pause |
| **Stop** | Recording/Paused | Stop recording; show confirmation dialog; save file |
| **Bookmark** | Recording | Insert a timestamp bookmark (stored in metadata) |

#### 4.2.5 Recording Behavior

- Show real-time waveform visualization using audio amplitude data.
- Display elapsed recording time (excluding paused duration).
- Keep screen awake during recording (`Wakelock`).
- Show a persistent notification while recording in background.
- If the app is killed during recording, save whatever audio has been captured so far.
- Auto-save every 60 seconds to prevent data loss on crash.
- File naming convention: `meeting_YYYYMMDD_HHMMSS.wav` (then `.flac` after compression).
- After stopping, automatically trigger FLAC compression in background.

#### 4.2.6 Real-Time Transcription (Stretch Goal)

If the device has sufficient processing power (modern flagship with 8+ GB RAM):
- Run whisper.cpp in streaming mode during recording.
- Display real-time partial transcription below the waveform.
- Use a smaller Whisper model (tiny or base) for real-time to maintain performance.
- Show text appearing with a slight delay (~2-5 seconds behind real-time).
- Mark real-time text as "draft" — the final transcription after recording will be more accurate.

If real-time transcription is not feasible or the device is not powerful enough:
- Skip real-time display and show "Transcription will begin after recording stops."
- Process the full audio file after recording with a larger, more accurate model.

**Detection logic**: On first launch, run a quick benchmark (transcribe 5 seconds of silence) to determine if real-time is viable. Store the result. Allow user to override in Settings.

---

### 4.3 Speech-to-Text (STT)

#### 4.3.1 Local STT Engine — whisper.cpp

**Primary engine**: whisper.cpp compiled as a shared library, called via Dart FFI.

##### Model Management

| Model | Size (GGML) | RAM Required | Quality | Recommended For |
|-------|-------------|-------------|---------|-----------------|
| tiny | ~75 MB | ~400 MB | Low | Quick test / real-time preview |
| base | ~142 MB | ~500 MB | Fair | Light notes |
| small | ~466 MB | ~1 GB | Good | General meetings (default) |
| medium | ~1.5 GB | ~2.5 GB | Very good | Important meetings |
| large-v3 | ~3 GB | ~4.5 GB | Best | Critical accuracy needs |

- Ship with the **tiny** model bundled in the APK/IPA for immediate use.
- On first launch, prompt the user to download the **small** model (recommended) via in-app model manager.
- Models are stored in the app's internal storage under `models/`.
- Show download progress, support pause/resume for large model downloads.
- Allow model deletion to free space.
- Display model size, estimated quality, and processing speed in the model selection UI.

##### Transcription Parameters

These should be configurable in Settings with sensible defaults:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `language` | `ko` (Korean) | Target language for recognition |
| `beam_size` | 5 | Beam search width (higher = more accurate but slower) |
| `temperature` | 0.0 | Sampling temperature (0 = deterministic) |
| `initial_prompt` | Korean meeting context | Contextual prompt to guide recognition |
| `condition_on_previous_text` | false | Reduces hallucination loops in long meetings |
| `no_speech_threshold` | null (disabled) | Disabling prevents speech segment loss |
| `threads` | auto (CPU cores - 1) | Number of threads for inference |

##### Initial Prompt System

Replicate the Python project's prompt logic:
- Default Korean prompt: `"이것은 한국어 회의 녹음입니다. 참석자들이 업무에 대해 논의합니다."`
- Allow users to add custom domain terms (comma-separated) in Settings.
- Terms are automatically woven into a natural sentence: `"{base_prompt} 회의에서 {terms} 등의 용어가 언급될 수 있습니다."`
- For non-Korean languages, use only user-provided terms.

##### Processing Flow

1. Load Whisper model into memory (show loading indicator).
2. Read audio file (WAV/FLAC).
3. Run transcription with configured parameters.
4. Return segments: `[{start, end, text}, ...]`.
5. Show progress (percentage or spinner with elapsed time).
6. Free model from memory after processing to reclaim RAM.

#### 4.3.2 Cloud STT — OpenAI Whisper API

Available when user provides an API key in Settings.

- Use the OpenAI `/v1/audio/transcriptions` endpoint.
- Upload the compressed FLAC file.
- Support the same language and prompt configuration as local.
- Show upload progress and estimated cost per minute.
- Handle rate limits and errors gracefully with retry logic.
- Display a clear indicator that data is being sent to an external server.

#### 4.3.3 Cloud STT — Google Cloud Speech-to-Text

Available when user provides a Google Cloud API key.

- Use the long-running recognition API for files over 1 minute.
- Support Korean and other languages.
- Same privacy warning as OpenAI.

#### 4.3.4 STT Provider Selection

In Settings, the user chooses their STT provider:

```
STT Engine
├── 🟢 Local (whisper.cpp) — Default, no internet required
│     └── Model: [tiny | base | small | medium | large-v3]
├── ☁️ OpenAI Whisper API — Requires API key
│     └── API Key: [••••••••••••]
└── ☁️ Google Cloud STT — Requires API key
      └── API Key: [••••••••••••]
```

---

### 4.4 Speaker Diarization

#### 4.4.1 Overview

Speaker diarization identifies "who spoke when" by clustering audio segments by voice characteristics.

#### 4.4.2 Local Diarization — sherpa-onnx

**Primary engine**: [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) provides speaker diarization models that run on-device via ONNX Runtime.

- Use the speaker diarization pipeline from sherpa-onnx.
- Models are ~20-50 MB (significantly smaller than pyannote).
- Runs on CPU; no GPU required.
- Supports configuration:
  - `num_speakers`: Fixed number of speakers (if known).
  - `max_speakers`: Maximum speakers to detect.
- Output: list of `{start, end, speaker_label}` segments.

##### Merging Logic (from reference implementation)

The merging of STT segments with diarization segments must replicate the Python project's logic:

```
For each Whisper text segment:
  1. Find all diarization segments that overlap in time.
  2. Calculate overlap duration per speaker.
  3. Assign the speaker with the most overlap.
  4. If consecutive segments have the same speaker and gap < 1.5 seconds:
     → Merge them into a single segment.
  5. If no diarization segment overlaps → label as "Unknown".
```

#### 4.4.3 Cloud Diarization

If local diarization quality is insufficient, users can opt into cloud services:

- **Option 1**: Send audio to a user-provided API endpoint that returns diarization data.
- **Option 2**: Integration with services like AssemblyAI, Rev.ai, or similar that offer diarization APIs.
- Allow API key configuration in Settings.

#### 4.4.4 Diarization Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Enabled | true | Toggle diarization on/off |
| Number of speakers | 0 (auto-detect) | Set if number of participants is known |
| Max speakers | 0 (unlimited) | Upper bound on detected speakers |
| Skip if over N minutes | 90 | Skip diarization for very long recordings |
| Engine | Local | Local or Cloud |

#### 4.4.5 Speaker Label Management

- Default labels: `SPEAKER_00`, `SPEAKER_01`, etc.
- Allow users to rename speakers after transcription (e.g., `SPEAKER_00` → `김팀장`).
- Renamed labels persist and are used in all exports.
- Allow "speaker remapping": merge two speaker labels if the algorithm incorrectly split one person into two.

---

### 4.5 AI Analysis & Summarization

#### 4.5.1 Overview

After transcription, the app can analyze the transcript to generate structured summaries, action items, and key decisions.

#### 4.5.2 Local LLM — llama.cpp

**Primary engine**: llama.cpp compiled as a shared library, called via Dart FFI.

##### Model Selection

| Model | Size (GGUF Q4) | RAM | Quality | Notes |
|-------|----------------|-----|---------|-------|
| Llama 3.2 1B | ~0.7 GB | ~1.5 GB | Basic | Suitable for simple summaries |
| Llama 3.2 3B | ~1.8 GB | ~3 GB | Good | Recommended default |
| Phi-3 Mini (3.8B) | ~2.2 GB | ~3.5 GB | Good | Strong multilingual support |
| Gemma 2 2B | ~1.4 GB | ~2.5 GB | Good | Efficient, good Korean |

- Do **not** bundle LLM models in the APK (too large).
- On first use, prompt user to download a recommended model.
- In-app model manager with download progress, pause/resume.
- Support GGUF format models (standard for llama.cpp).
- Allow users to import custom GGUF models from device storage.

##### Analysis Prompt Templates

Built-in prompt templates (user can customize):

**Template 1: Full Summary (Default)**
```
Analyze the following meeting transcript and provide a structured summary:

1. Meeting Overview (participants, main topics)
2. Key Discussion Points (grouped by topic, include speaker opinions)
3. Decisions Made
4. Action Items (assignee, deadline if mentioned)
5. Unresolved Issues / Items Requiring Follow-up
6. Executive Summary (3 sentences or fewer)

Transcript:
{transcript_text}
```

**Template 2: Action Items Only**
```
Extract all action items from the following meeting transcript.
For each item, identify: the task, the responsible person (if mentioned),
and the deadline (if mentioned).

Transcript:
{transcript_text}
```

**Template 3: Key Decisions**
```
List all decisions made during this meeting.
Include who proposed it and whether it was agreed upon.

Transcript:
{transcript_text}
```

**Template 4: Custom Query**
```
{user_query}

Transcript:
{transcript_text}
```

##### Processing Flow

1. User taps "Analyze" on a transcript detail screen.
2. Show template selection (or use default).
3. Load LLM model (show loading indicator with RAM usage).
4. Inject transcript into prompt template.
5. Run inference with streaming output (show text appearing in real-time).
6. Save analysis result linked to the transcript.
7. Free model from memory after completion.

#### 4.5.3 Cloud LLM — OpenAI GPT API

Available when user provides an API key:

- Use the Chat Completions API (`gpt-4o-mini` by default, configurable).
- Same prompt templates as local.
- Show estimated token count and approximate cost before sending.
- Stream the response for real-time display.
- Require explicit user confirmation before sending transcript to external API (privacy).

#### 4.5.4 Analysis Results Display

- Show the analysis in a clean, readable Markdown-rendered view.
- Allow copy-to-clipboard for any section.
- Support re-running analysis with a different template or custom query.
- Store analysis history (multiple analyses per transcript).

---

### 4.6 Transcript Output & Formatting

#### 4.6.1 JSON Format

Primary storage format, compatible with the Python reference implementation:

```json
{
  "id": "uuid-v4",
  "source_audio": "meeting_20260407_145924.flac",
  "language": "ko",
  "stt_engine": "whisper.cpp",
  "stt_model": "small",
  "created_at": "2026-04-07T23:51:48+09:00",
  "duration_seconds": 5226,
  "segments": [
    {
      "speaker": "SPEAKER_00",
      "start": 0.0,
      "end": 46.78,
      "text": "AI를 어떤 걸 할 수 있을까 해서..."
    },
    {
      "speaker": "SPEAKER_04",
      "start": 46.78,
      "end": 55.58,
      "text": "대표님께 재미있게 봐달라고..."
    }
  ],
  "full_text": "[00:00:00] SPEAKER_00: AI를 어떤 걸...\n[00:00:46] SPEAKER_04: 대표님께...",
  "speaker_map": {
    "SPEAKER_00": "발표자",
    "SPEAKER_04": "질문자A"
  },
  "bookmarks": [
    {"time": 300.0, "label": "Important decision"}
  ],
  "analysis": [
    {
      "id": "uuid-v4",
      "template": "full_summary",
      "engine": "llama.cpp",
      "model": "llama-3.2-3b",
      "created_at": "2026-04-08T00:15:00+09:00",
      "result": "## Meeting Summary\n..."
    }
  ]
}
```

#### 4.6.2 Markdown Format

Human-readable format for export and sharing:

```markdown
# Meeting Transcript — 2026-04-07

## Meeting Info
- **Audio File**: meeting_20260407_145924.flac
- **Created**: 2026-04-07 23:51:48
- **Speakers**: 발표자, 질문자A, SPEAKER_02, ...
- **Duration**: 01:27:06

---

## Transcript

### 발표자

**[00:00:00]** AI를 어떤 걸 할 수 있을까 해서...

### 질문자A

**[00:00:46]** 대표님께 재미있게 봐달라고...

---

## AI Summary

(Analysis content here if available)
```

---

### 4.7 Storage & Export

#### 4.7.1 Internal Storage (Default)

- All recordings, transcripts, and models stored in app-private internal storage.
- Not accessible to other apps or via file manager (privacy).
- Structure:
  ```
  {app_internal}/
  ├── recordings/      # FLAC/WAV audio files
  ├── transcripts/     # JSON transcript files
  ├── models/
  │   ├── whisper/     # Whisper GGML models
  │   ├── llm/         # LLM GGUF models
  │   └── diarization/ # Diarization ONNX models
  └── exports/         # Temporary export staging area
  ```

#### 4.7.2 Local Export

Export to device's shared storage (Downloads, Documents):
- Export formats: JSON, Markdown, Plain Text, PDF.
- Export audio: Original FLAC/WAV.
- Export bundle: ZIP containing audio + transcript + analysis.
- User selects destination folder via system file picker.

#### 4.7.3 Cloud Export

Sync or export to user-configured cloud storage:

| Service | Method | Notes |
|---------|--------|-------|
| Google Drive | OAuth 2.0 or API key | Create a "VoiceNote" folder |
| Dropbox | OAuth 2.0 | Create a "VoiceNote" folder |
| iCloud (iOS only) | Native API | Automatic sync if enabled |
| Custom WebDAV | URL + credentials | For self-hosted solutions |

- Cloud export is **push-only** (not sync). User explicitly triggers export.
- Show upload progress.
- Do not auto-upload. Respect privacy-first principle.

#### 4.7.4 Share

- Use the OS native share sheet to share transcript files.
- Share options: Markdown text, plain text, JSON file, PDF file.
- Share via any installed app (email, messaging, notes, etc.).

---

### 4.8 Recording Management

#### 4.8.1 Home Screen — Recording List

The main screen after PIN unlock shows all recordings as a scrollable list.

```
┌──────────────────────────────────┐
│  VoiceNote AI          🔍  ⚙️   │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 📋 Weekly Team Meeting     │  │
│  │ 2026-04-07 · 01:27:06     │  │
│  │ 6 speakers · Transcribed ✓│  │
│  │ ▂▃▅▇▅▃▂▁▂▃▅▇▅▃▂          │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 📋 1:1 with Manager        │  │
│  │ 2026-04-05 · 00:32:15     │  │
│  │ 2 speakers · Analyzed ✓   │  │
│  │ ▂▃▅▃▂▁▂▃▅▃▂              │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🎤 Sprint Planning         │  │
│  │ 2026-04-03 · 00:55:42     │  │
│  │ Processing... 45%         │  │
│  │ ████████░░░░░░░░          │  │
│  └────────────────────────────┘  │
│                                  │
│                                  │
│              ┌──────┐            │
│              │  🎙️  │            │  ← Floating Action Button
│              └──────┘            │
└──────────────────────────────────┘
```

#### 4.8.2 Recording Card Information

Each card displays:
- Title (editable, default: "Recording YYYY-MM-DD HH:MM")
- Date and time
- Duration
- Number of detected speakers
- Processing status: `Recording` | `Compressing` | `Transcribing` | `Diarizing` | `Analyzed` | `Error`
- Mini waveform thumbnail
- File size

#### 4.8.3 Recording Actions

Long-press or swipe on a card reveals actions:
- **Rename**: Edit the recording title.
- **Delete**: Delete with confirmation dialog. Deletes audio + transcript + analysis.
- **Export**: Export this recording (audio + transcript).
- **Share**: Share transcript via OS share sheet.

#### 4.8.4 Transcript Detail Screen

Tapping a recording card navigates to the detail screen:

- **Tabs**: Transcript | Analysis | Info
- **Transcript Tab**:
  - Full transcript with speaker labels and timestamps.
  - Each speaker's name shown as a colored badge.
  - Tap a segment to play that portion of audio.
  - Edit button to correct transcription errors.
  - Tap speaker label to rename.
- **Analysis Tab**:
  - "Analyze" button if not yet analyzed.
  - Analysis result rendered as Markdown.
  - Re-analyze with different template.
  - Analysis history.
- **Info Tab**:
  - Audio file details (format, size, duration, sample rate).
  - Processing details (STT engine, model, processing time).
  - Bookmarks list.

#### 4.8.5 Search

- Full-text search across all transcripts.
- Search by: transcript text, speaker name, recording title, date range.
- Results highlight matching text in context.
- Tap a result to navigate to that segment in the transcript.

#### 4.8.6 Sorting & Filtering

- Sort by: Date (newest/oldest), Duration, Title.
- Filter by: Status (transcribed, analyzed, pending), Date range, Has bookmarks.

---

### 4.9 Settings

#### 4.9.1 Settings Structure

```
Settings
├── 🔒 Security
│   ├── Change PIN
│   ├── Biometric Unlock [toggle]
│   └── Auto-lock timeout [30s / 1min / 5min / never]
│
├── 🎙️ Recording
│   ├── Audio quality [16kHz / 44.1kHz]
│   ├── Auto-compress to FLAC [toggle, default: on]
│   └── Real-time transcription [toggle, default: off]
│
├── 📝 Speech-to-Text
│   ├── Engine [Local / OpenAI API / Google API]
│   ├── Whisper Model [tiny / base / small / medium / large-v3]
│   ├── Model Manager [download / delete models]
│   ├── Language [Korean / English / Japanese / ...]
│   ├── Beam Size [1-10, default: 5]
│   ├── Custom Terms [comma-separated domain words]
│   └── API Keys (if cloud engine selected)
│       ├── OpenAI API Key [encrypted input]
│       └── Google Cloud API Key [encrypted input]
│
├── 👥 Speaker Diarization
│   ├── Enable diarization [toggle, default: on]
│   ├── Engine [Local / Cloud]
│   ├── Default number of speakers [0 = auto]
│   ├── Max speakers [0 = unlimited]
│   └── Skip if over [minutes, default: 90]
│
├── 🤖 AI Analysis
│   ├── Engine [Local LLM / OpenAI API]
│   ├── Local Model [download / manage GGUF models]
│   ├── Default template [Full Summary / Action Items / ...]
│   ├── Custom prompt templates [add / edit / delete]
│   └── OpenAI API Key [encrypted input]
│       └── GPT Model [gpt-4o-mini / gpt-4o / ...]
│
├── 💾 Storage & Export
│   ├── Storage usage [used / available]
│   ├── Default export format [Markdown / JSON / PDF]
│   ├── Cloud export destination [none / Google Drive / Dropbox / WebDAV]
│   ├── Cloud credentials [OAuth or credentials input]
│   └── Clear all data [destructive, requires PIN]
│
├── 🌐 Language & Region
│   ├── App language [Korean / English]
│   └── Date format [YYYY-MM-DD / MM/DD/YYYY]
│
└── ℹ️ About
    ├── Version
    ├── Open source licenses
    └── Privacy policy
```

---

## 5. UI/UX Design System

### 5.1 Color Palette — Soft Blue

The entire app uses a soft, light blue color scheme that is calming and professional.

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#5B9BD5` | Primary buttons, active states, FAB |
| `primaryLight` | `#A8D1F0` | Backgrounds, selected states |
| `primaryDark` | `#2E75B6` | Text on light backgrounds, headers |
| `primarySurface` | `#E8F4FD` | Card backgrounds, subtle fills |
| `primaryContainer` | `#D0E8F7` | Container backgrounds |
| `background` | `#F5F9FC` | Screen background |
| `surface` | `#FFFFFF` | Card surfaces, input fields |
| `surfaceVariant` | `#EDF2F7` | Dividers, secondary surfaces |
| `onPrimary` | `#FFFFFF` | Text/icons on primary color |
| `onBackground` | `#1A2B3C` | Primary text on background |
| `onSurface` | `#2D3E50` | Text on surfaces |
| `textSecondary` | `#6B8299` | Secondary text, timestamps |
| `textTertiary` | `#9BB0C4` | Hints, placeholders |
| `error` | `#E74C3C` | Error states, destructive actions |
| `success` | `#27AE60` | Success indicators |
| `warning` | `#F39C12` | Warnings |
| `recording` | `#E74C3C` | Recording indicator (red dot) |
| `divider` | `#D6E4EF` | Lines, borders |

### 5.2 Typography

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `headlineLarge` | 28sp | Bold | Screen titles |
| `headlineMedium` | 22sp | SemiBold | Section headers |
| `titleLarge` | 18sp | SemiBold | Card titles |
| `titleMedium` | 16sp | Medium | Subtitles |
| `bodyLarge` | 16sp | Regular | Primary body text, transcript |
| `bodyMedium` | 14sp | Regular | Secondary text |
| `bodySmall` | 12sp | Regular | Timestamps, metadata |
| `labelLarge` | 14sp | Medium | Button text |
| `labelSmall` | 11sp | Medium | Badges, chips |

**Font**: System default (Roboto on Android, SF Pro on iOS) for best readability.

### 5.3 Component Specs

#### Buttons
- **Primary**: Filled with `primary` color, rounded corners (12dp), elevation 2dp.
- **Secondary**: Outlined with `primary` border, transparent fill.
- **Text**: No border, `primary` text color.
- **Floating Action Button**: 56dp circle, `primary` fill, microphone icon, elevation 6dp.

#### Cards
- Background: `surface` (#FFFFFF).
- Border: 1dp `divider` color.
- Rounded corners: 16dp.
- Elevation: 1dp (subtle shadow).
- Padding: 16dp.
- Margin between cards: 12dp.

#### Speaker Badges
- Small rounded pill shapes with distinct soft colors per speaker:
  - SPEAKER_00: `#5B9BD5` (blue)
  - SPEAKER_01: `#7BC47F` (green)
  - SPEAKER_02: `#E8A87C` (orange)
  - SPEAKER_03: `#C084FC` (purple)
  - SPEAKER_04: `#F472B6` (pink)
  - SPEAKER_05+: rotating palette

#### PIN Input
- 4 large circular indicators (24dp diameter).
- Empty: outlined with `divider` color.
- Filled: solid `primary` color.
- Custom numeric keypad below with large touch targets (64dp per key).

### 5.4 Animations & Transitions

- **Screen transitions**: Slide from right (push), slide to right (pop).
- **PIN success**: Indicators briefly turn green with a check mark, then fade transition to Home.
- **PIN failure**: Shake animation (horizontal oscillation) on indicators.
- **Recording pulse**: Red dot with a subtle pulse animation.
- **Waveform**: Smooth, continuous audio level visualization.
- **Processing**: Indeterminate progress indicator with percentage when available.
- **List item appearance**: Subtle fade-in with slight upward slide.

### 5.5 Dark Mode

Support system dark mode with an inverted palette:

| Token | Light | Dark |
|-------|-------|------|
| `background` | `#F5F9FC` | `#0D1B2A` |
| `surface` | `#FFFFFF` | `#1B2838` |
| `onBackground` | `#1A2B3C` | `#E8F4FD` |
| `onSurface` | `#2D3E50` | `#D0E8F7` |
| `primary` | `#5B9BD5` | `#7CB8E8` |
| `primarySurface` | `#E8F4FD` | `#162A3D` |

---

## 6. Data Models

### 6.1 Recording

```dart
class Recording {
  final String id;               // UUID v4
  String title;                   // User-editable title
  final String audioFilePath;     // Relative path to audio file
  final DateTime createdAt;
  final double durationSeconds;
  final String audioFormat;       // "flac" or "wav"
  final int fileSizeBytes;
  final int sampleRate;           // 16000
  final int channels;             // 1
  RecordingStatus status;         // enum
  String? transcriptId;           // FK to Transcript
  List<Bookmark> bookmarks;
}

enum RecordingStatus {
  recording,
  compressing,
  pendingTranscription,
  transcribing,
  transcribed,
  analyzing,
  analyzed,
  error
}

class Bookmark {
  final double timeSeconds;
  String label;
}
```

### 6.2 Transcript

```dart
class Transcript {
  final String id;                // UUID v4
  final String recordingId;       // FK to Recording
  final String language;
  final String sttEngine;         // "whisper.cpp" | "openai" | "google"
  final String sttModel;          // "small", "gpt-4o-mini", etc.
  final DateTime createdAt;
  final double processingTimeSeconds;
  final List<Segment> segments;
  final String fullText;
  final Map<String, String> speakerMap;  // SPEAKER_00 -> "김팀장"
  List<AnalysisResult> analyses;
}

class Segment {
  final String speaker;           // "SPEAKER_00" or mapped name
  final double startSeconds;
  final double endSeconds;
  String text;                    // Editable for corrections
}
```

### 6.3 AnalysisResult

```dart
class AnalysisResult {
  final String id;                // UUID v4
  final String transcriptId;     // FK to Transcript
  final String template;          // "full_summary" | "action_items" | "custom"
  final String engine;            // "llama.cpp" | "openai"
  final String model;             // "llama-3.2-3b" | "gpt-4o-mini"
  final String prompt;            // The actual prompt sent
  final DateTime createdAt;
  final double processingTimeSeconds;
  final String result;            // Markdown-formatted result text
}
```

### 6.4 AppSettings

```dart
class AppSettings {
  // Security
  String pinHash;
  bool biometricEnabled;
  int autoLockTimeoutSeconds;     // 30, 60, 300, -1 (never)

  // Recording
  int sampleRate;                 // 16000 or 44100
  bool autoCompressFlac;
  bool realtimeTranscription;

  // STT
  SttEngine sttEngine;            // local, openai, google
  String whisperModel;            // tiny, base, small, medium, large-v3
  String language;                // ko, en, ja, ...
  int beamSize;
  String customTerms;
  String? openaiApiKey;           // Encrypted
  String? googleApiKey;           // Encrypted

  // Diarization
  bool diarizationEnabled;
  DiarizationEngine diarizationEngine;
  int numSpeakers;
  int maxSpeakers;
  int skipIfOverMinutes;

  // Analysis
  AnalysisEngine analysisEngine;  // local, openai
  String llmModel;
  String defaultTemplate;
  List<CustomTemplate> customTemplates;
  String? openaiAnalysisApiKey;   // Encrypted (can reuse STT key)
  String openaiGptModel;

  // Export
  ExportFormat defaultExportFormat;
  CloudDestination? cloudDestination;
}
```

---

## 7. File & Directory Structure

### 7.1 Internal App Storage

```
{app_data_dir}/
├── recordings/
│   ├── meeting_20260407_145924.flac
│   ├── meeting_20260405_093000.flac
│   └── ...
├── transcripts/
│   ├── {uuid}.json
│   └── ...
├── models/
│   ├── whisper/
│   │   ├── ggml-tiny.bin
│   │   ├── ggml-small.bin
│   │   └── ...
│   ├── llm/
│   │   ├── llama-3.2-3b-q4.gguf
│   │   └── ...
│   └── diarization/
│       └── sherpa-onnx-speaker-diarization/
├── database/
│   └── voicenote.isar     # or .hive
└── temp/
    └── ...                # Temporary processing files
```

---

## 8. Third-Party Dependencies

### 8.1 Flutter Packages

| Package | Purpose | Required |
|---------|---------|----------|
| `flutter_riverpod` or `flutter_bloc` | State management | Yes |
| `go_router` | Navigation / routing | Yes |
| `flutter_secure_storage` | Encrypted PIN and API key storage | Yes |
| `isar` or `hive` | Local database | Yes |
| `path_provider` | Platform-specific directory paths | Yes |
| `permission_handler` | Microphone and storage permissions | Yes |
| `wakelock_plus` | Keep screen on during recording | Yes |
| `record` | Audio recording (cross-platform) | Yes |
| `just_audio` | Audio playback | Yes |
| `flutter_local_notifications` | Recording notification | Yes |
| `share_plus` | OS share sheet | Yes |
| `file_picker` | Export file destination | Yes |
| `flutter_markdown` | Render analysis results | Yes |
| `intl` | Date/time formatting | Yes |
| `uuid` | Generate unique IDs | Yes |
| `crypto` | PIN hashing | Yes |
| `archive` | ZIP creation for export bundles | Yes |
| `local_auth` | Biometric authentication | Optional |
| `http` / `dio` | HTTP client for API calls | For cloud features |
| `googleapis` | Google Drive export | Optional |
| `connectivity_plus` | Network status detection | For cloud features |

### 8.2 Native Libraries

| Library | Source | Platform | Purpose |
|---------|--------|----------|---------|
| whisper.cpp | [github.com/ggerganov/whisper.cpp](https://github.com/ggerganov/whisper.cpp) | Android (.so), iOS (.framework) | Local STT |
| llama.cpp | [github.com/ggerganov/llama.cpp](https://github.com/ggerganov/llama.cpp) | Android (.so), iOS (.framework) | Local LLM |
| sherpa-onnx | [github.com/k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) | Android (.so), iOS (.framework) | Speaker diarization |

These must be cross-compiled for the target architectures:
- Android: `arm64-v8a`, `armeabi-v7a`, optionally `x86_64` (emulator)
- iOS: `arm64`

---

## 9. Build & Deployment

### 9.1 Android

- **Minimum SDK**: API 26 (Android 8.0) — required for modern audio APIs.
- **Target SDK**: Latest stable (API 34+).
- **APK size target**: < 100 MB (excluding downloadable models).
- **Permissions required**:
  - `RECORD_AUDIO` — microphone access.
  - `POST_NOTIFICATIONS` — recording notification (Android 13+).
  - `FOREGROUND_SERVICE` — background recording.
  - `FOREGROUND_SERVICE_MEDIA_PLAYBACK` — audio playback in background.
  - `INTERNET` — only for cloud API features (optional).
  - `WRITE_EXTERNAL_STORAGE` — export to shared storage (pre-Android 10).
  - `USE_BIOMETRIC` — fingerprint/face unlock (optional).

### 9.2 iOS

- **Minimum iOS**: 16.0
- **Permissions**:
  - `NSMicrophoneUsageDescription` — microphone.
  - `NSFaceIDUsageDescription` — Face ID (optional).
- **App Transport Security**: Allow connections to user-configured API endpoints.

### 9.3 Model Download Infrastructure

Models are hosted on a CDN or mirrors and downloaded on-demand:
- Show total size before download.
- Support pause/resume (HTTP range requests).
- Verify integrity with SHA-256 checksum.
- Store in app-private directory.
- Alternative: allow user to import model files from device storage (for offline/airgapped use).

---

## 10. Performance Requirements

| Metric | Target | Notes |
|--------|--------|-------|
| App launch to PIN screen | < 1 second | Cold start |
| PIN validation | < 100ms | Hash comparison |
| Recording start latency | < 500ms | From button tap to capture |
| Whisper tiny (1 min audio) | < 30 seconds | On mid-range device (Snapdragon 7 series) |
| Whisper small (1 min audio) | < 90 seconds | On mid-range device |
| Whisper small (1 min audio) | < 30 seconds | On flagship (Snapdragon 8 series) |
| LLM inference (3B, 1000 tokens) | < 60 seconds | On flagship device |
| Diarization (1 min audio) | < 20 seconds | On mid-range device |
| Memory (idle) | < 100 MB | Without models loaded |
| Memory (during STT) | < 1.5 GB | With small model |
| Memory (during LLM) | < 3.5 GB | With 3B model |
| Battery drain (recording) | < 5%/hour | Optimized audio capture |

---

## 11. Testing Strategy

### 11.1 Unit Tests

- All service classes (STT, diarization, analysis, export).
- Data models serialization/deserialization.
- PIN hashing and validation.
- Timestamp formatting utilities.
- Merging logic (whisper segments + diarization).

### 11.2 Widget Tests

- PIN entry screen (input, validation, lockout).
- Recording controls (start, pause, resume, stop).
- Recording list (display, sort, filter).
- Transcript viewer (rendering, speaker badges).
- Settings screens (all toggles, inputs).

### 11.3 Integration Tests

- Full recording → transcription → analysis flow.
- Cloud API fallback when local fails.
- Export to file system.
- Model download and loading.

### 11.4 Performance Tests

- STT inference time across different model sizes and devices.
- Memory profiling during model loading.
- Battery drain during 1-hour recording.

---

## 12. Future Considerations

These features are **not** in the MVP but should be considered in the architecture:

| Feature | Description |
|---------|-------------|
| **Multi-language meetings** | Auto-detect language switches within a single meeting |
| **Real-time translation** | Translate transcript segments to another language |
| **Meeting templates** | Pre-configured settings for different meeting types (standup, 1:1, all-hands) |
| **Collaborative editing** | Share transcripts with team members for collaborative correction |
| **Calendar integration** | Auto-title recordings based on calendar events |
| **Wear OS / watchOS** | Start recording from smartwatch |
| **Widget** | Home screen widget for quick recording start |
| **Scheduled recording** | Auto-start recording at scheduled times |
| **Voice commands** | "Hey VoiceNote, start recording" |
| **Transcript comparison** | Compare two different STT results for the same audio |
| **Speaker enrollment** | Pre-register voices for more accurate speaker identification |
| **Transcript versioning** | Track edit history of transcripts |

---

## Appendix A: Reference Implementation Details

The original Python project (`Record_analyzer`) implements the following flow that must be replicated:

### A.1 Recording Parameters
- Sample rate: 16,000 Hz
- Channels: 1 (mono)
- Format: 16-bit PCM WAV
- Chunk size: 1024 frames
- Post-recording: WAV → FLAC compression via ffmpeg

### A.2 Whisper Configuration
- Model resolution: local `.pt` file in `models/` directory preferred; fallback to download.
- Device: CUDA > MPS > CPU (for mobile: CPU only, or NNAPI/CoreML if available).
- Transcription options: `language`, `beam_size`, `temperature=0.0`, `condition_on_previous_text=False`, `no_speech_threshold=None`.
- Initial prompt: Korean base sentence + optional user domain terms.
- MPS workaround: Whisper forced to CPU even when MPS available (relevant for macOS; mobile uses CPU or neural engine).

### A.3 Speaker Diarization
- Pipeline: pyannote/speaker-diarization-3.1 (mobile equivalent: sherpa-onnx).
- Supports both pyannote 3.x and 4.x output formats.
- Merging algorithm: overlap-based speaker vote per Whisper segment, consecutive same-speaker merge if gap < 1.5s.
- Safety: skip diarization if audio exceeds configurable minute threshold.

### A.4 Output Format
- JSON with: `source_audio`, `language`, `whisper_model`, `segments` (speaker, start, end, text), `full_text`.
- Markdown with: metadata header, speaker-grouped dialogue with timestamps.
- Timestamp format: `HH:MM:SS`.

---

## Appendix B: API Endpoint References

### B.1 OpenAI Whisper API
```
POST https://api.openai.com/v1/audio/transcriptions
Headers:
  Authorization: Bearer {api_key}
Body (multipart/form-data):
  file: {audio_file}
  model: "whisper-1"
  language: "ko"
  prompt: "{initial_prompt}"
  response_format: "verbose_json"
  timestamp_granularities: ["segment"]
```

### B.2 OpenAI Chat Completions API
```
POST https://api.openai.com/v1/chat/completions
Headers:
  Authorization: Bearer {api_key}
  Content-Type: application/json
Body:
{
  "model": "gpt-4o-mini",
  "messages": [
    {"role": "system", "content": "You are a meeting analyst..."},
    {"role": "user", "content": "{prompt_with_transcript}"}
  ],
  "stream": true
}
```

### B.3 Google Cloud Speech-to-Text
```
POST https://speech.googleapis.com/v1/speech:longrunningrecognize
Headers:
  Authorization: Bearer {api_key}
Body:
{
  "config": {
    "encoding": "FLAC",
    "sampleRateHertz": 16000,
    "languageCode": "ko-KR",
    "enableSpeakerDiarization": true,
    "diarizationSpeakerCount": 2
  },
  "audio": {
    "content": "{base64_encoded_audio}"
  }
}
```

---

## Appendix C: Glossary

| Term | Definition |
|------|-----------|
| STT | Speech-to-Text — converting spoken audio into written text |
| Diarization | The process of identifying "who spoke when" in an audio recording |
| GGML / GGUF | Quantized model formats used by whisper.cpp and llama.cpp for efficient inference |
| ONNX | Open Neural Network Exchange — portable model format used by sherpa-onnx |
| FFI | Foreign Function Interface — Dart's mechanism for calling native C/C++ code |
| FLAC | Free Lossless Audio Codec — lossless audio compression format |
| Segment | A continuous speech block with start time, end time, speaker label, and text |
| Beam Search | A search algorithm used in STT to find the most probable text output |
| Platform Channel | Flutter's mechanism for calling platform-specific (Android/iOS) native code |

---

*End of specification. This document provides all necessary information for an AI agent or development team to build the VoiceNote AI application from scratch.*
