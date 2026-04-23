$ErrorActionPreference = 'Stop'

param(
  [Parameter(Mandatory = $true)]
  [string]$WhisperCliPath
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$assetDir = Join-Path $projectRoot 'android\app\src\main\assets\whisper\arm64-v8a'
$target = Join-Path $assetDir 'whisper-cli'

if (-not (Test-Path $WhisperCliPath)) {
  throw "whisper-cli not found: $WhisperCliPath"
}

New-Item -ItemType Directory -Force -Path $assetDir | Out-Null
Copy-Item -LiteralPath $WhisperCliPath -Destination $target -Force

Write-Host "Bundled whisper-cli installed:"
Write-Host $target
Write-Host ""
Write-Host "Next step:"
Write-Host "flutter build apk --release"
