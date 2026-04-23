$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$logPath = Join-Path $projectRoot 'build\apk_release_build.log'
$exitCodePath = Join-Path $projectRoot 'build\apk_release_build.exitcode.txt'

if (Test-Path $logPath) {
  Remove-Item $logPath -Force
}
if (Test-Path $exitCodePath) {
  Remove-Item $exitCodePath -Force
}

& 'C:\src\flutter\bin\flutter.bat' build apk --release *>&1 | Tee-Object -FilePath $logPath
$code = $LASTEXITCODE
Set-Content -Path $exitCodePath -Value $code
exit $code
