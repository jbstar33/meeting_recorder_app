param(
  [string]$PackageName = "com.onestore.meeting_recorder_app",
  [string]$WhisperCliPath = "",
  [string]$ModelPath = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($WhisperCliPath) -or [string]::IsNullOrWhiteSpace($ModelPath)) {
  Write-Host "사용법:"
  Write-Host "powershell -ExecutionPolicy Bypass -File .\tools\android\setup_whisper_cpp_android.ps1 -WhisperCliPath <arm64 whisper-cli 경로> -ModelPath <ggml-*.bin 경로>"
  exit 1
}

if (-not (Test-Path $WhisperCliPath)) {
  throw "whisper-cli 파일을 찾을 수 없습니다: $WhisperCliPath"
}

if (-not (Test-Path $ModelPath)) {
  throw "모델 파일을 찾을 수 없습니다: $ModelPath"
}

$adb = "adb"

& $adb devices
if ($LASTEXITCODE -ne 0) { throw "adb devices 실패" }

& $adb shell "run-as $PackageName mkdir -p files/models"
if ($LASTEXITCODE -ne 0) {
  throw "run-as 실패. 디버그 빌드 앱이 설치되어 있고 패키지명이 맞는지 확인해 주세요."
}

& $adb push $WhisperCliPath "/sdcard/Download/whisper-cli"
if ($LASTEXITCODE -ne 0) { throw "whisper-cli push 실패" }

& $adb push $ModelPath "/sdcard/Download/ggml-model.bin"
if ($LASTEXITCODE -ne 0) { throw "model push 실패" }

& $adb shell "run-as $PackageName cp /sdcard/Download/whisper-cli files/whisper-cli"
if ($LASTEXITCODE -ne 0) { throw "whisper-cli 복사 실패" }

& $adb shell "run-as $PackageName cp /sdcard/Download/ggml-model.bin files/models/ggml-base.bin"
if ($LASTEXITCODE -ne 0) { throw "model 복사 실패" }

& $adb shell "run-as $PackageName chmod 755 files/whisper-cli"
if ($LASTEXITCODE -ne 0) { throw "chmod 실패" }

Write-Host ""
Write-Host "완료:"
Write-Host "- /data/user/0/$PackageName/files/whisper-cli"
Write-Host "- /data/user/0/$PackageName/files/models/ggml-base.bin"
Write-Host ""
Write-Host "앱 설정 > 로컬 STT / 화자 분리에서 Android 경로를 위와 동일하게 맞춰 주세요."
