Place the Android arm64 `whisper-cli` binary here before building APK:

- `android/app/src/main/assets/whisper/arm64-v8a/whisper-cli`

At runtime, the app installs this bundled binary into app-private storage and
downloads only the model file.
