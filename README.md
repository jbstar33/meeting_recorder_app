# Meeting Recorder App

This repository contains a Flutter meeting recorder app focused on local capture, transcript editing, search, and export.

## Included

- home dashboard
- recording screen
- transcript list and detail screens
- transcript search
- markdown export
- settings screen

## Run

After installing Flutter:

```powershell
flutter pub get
flutter run
```

## Cloud STT (Phase 1)

To enable cloud transcription after recording stops, run with `OPENAI_API_KEY`:

```powershell
flutter run --dart-define=OPENAI_API_KEY=YOUR_KEY
```

You can also open the app Settings screen and save the API key there.

Optional overrides:

```powershell
flutter run --dart-define=OPENAI_BASE_URL=https://api.openai.com/v1 --dart-define=OPENAI_STT_MODEL=whisper-1
```

## Local STT + Speaker Diarization

The app now supports local transcription and speaker separation on desktop (I/O platforms).

1. Install Python dependencies:

```powershell
python -m pip install -r tools/local_stt/requirements.txt
```

2. Open the app Settings screen:
- set `변환 엔진` to `로컬`
- set `Python 명령어` (default: `python`)
- set `Whisper 모델` (example: `small`)
- optional: set `Hugging Face Token` for pyannote speaker diarization quality

3. Record audio and stop recording:
- local transcription runs automatically
- transcript segments are saved with speaker labels

If HF token is not provided, the pipeline still runs local STT and falls back to a single-speaker label.

## Android Local STT (whisper.cpp)

Android local STT uses `whisper.cpp` binary execution through a Flutter MethodChannel.

1. Prepare files on your PC:
- arm64 Android `whisper-cli` binary
- `ggml-*.bin` model file (for example `ggml-base.bin`)

2. Install debug app to phone once:

```powershell
flutter run -d <android-device-id>
```

3. Push binary/model into app private storage:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\android\setup_whisper_cpp_android.ps1 -WhisperCliPath <PATH_TO_WHISPER_CLI> -ModelPath <PATH_TO_GGML_MODEL>
```

4. In app Settings:
- set `변환 엔진` to `로컬`
- `Android whisper-cli 경로`:
  `/data/user/0/com.onestore.meeting_recorder_app/files/whisper-cli`
- `Android 모델 경로`:
  `/data/user/0/com.onestore.meeting_recorder_app/files/models/ggml-base.bin`

5. Record and stop. The app runs local STT on-device.

### Phone-only setup (no PC copy command)

You can now install on phone directly:

1. In app Settings > `로컬 STT / 화자 분리`
2. Fill:
- `Android whisper-cli URL`
- `Android 모델 URL`
3. Tap `앱에서 다운로드/설치 (Android)`
4. After success, keep engine as `로컬` and test recording.

Note:
- This flow requires the app package to match `com.onestore.meeting_recorder_app`.
- `run-as` based copy works reliably with debug builds.
- Speaker separation uses whisper turn markers (`-tdrz`) as a lightweight two-speaker heuristic.

## Branching

See [docs/branching_strategy.md](docs/branching_strategy.md) for the branch and PR workflow used in this repository.
