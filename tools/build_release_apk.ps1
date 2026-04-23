$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Persisted JDK path fallback (adjust if your JDK location changes)
if (-not $env:JAVA_HOME -or -not (Test-Path $env:JAVA_HOME)) {
  $jdkPath = "C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"
  if (Test-Path $jdkPath) {
    $env:JAVA_HOME = $jdkPath
  }
}

if ($env:JAVA_HOME) {
  $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
}

$flutter = "C:\src\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
  throw "Flutter not found: $flutter"
}

& $flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }

& $flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "flutter build apk --release failed" }

Write-Host ""
Write-Host "APK build complete:"
Write-Host "build\app\outputs\flutter-apk\app-release.apk"
