param(
  [string]$WhisperRepoUrl = 'https://github.com/ggml-org/whisper.cpp.git',
  [string]$WhisperRef = 'master',
  [string]$AndroidAbi = 'arm64-v8a',
  [string]$AndroidPlatform = 'android-26'
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$thirdPartyRoot = Join-Path $projectRoot 'third_party'
$srcDir = Join-Path $thirdPartyRoot 'whisper.cpp'
$buildDir = Join-Path $srcDir 'build-android-arm64'
$assetDir = Join-Path $projectRoot 'android\app\src\main\assets\whisper\arm64-v8a'
$outputPath = Join-Path $assetDir 'whisper-cli'
$jniLibDir = Join-Path $projectRoot 'android\app\src\main\jniLibs\arm64-v8a'

$cmakeExe = 'C:\CP\cmake\3.22.1\bin\cmake.exe'
$ninjaExe = 'C:\CP\cmake\3.22.1\bin\ninja.exe'
$ndkRoot = 'C:\CP\ndk\28.2.13676358'
$toolchainFile = Join-Path $ndkRoot 'build\cmake\android.toolchain.cmake'

if (-not (Test-Path $cmakeExe)) {
  throw "cmake not found: $cmakeExe"
}
if (-not (Test-Path $ninjaExe)) {
  throw "ninja not found: $ninjaExe"
}
if (-not (Test-Path $toolchainFile)) {
  throw "android toolchain file not found: $toolchainFile"
}

New-Item -ItemType Directory -Force -Path $thirdPartyRoot | Out-Null

if (-not (Test-Path $srcDir)) {
  git clone --depth 1 --branch $WhisperRef $WhisperRepoUrl $srcDir
} else {
  Push-Location $srcDir
  try {
    git fetch origin $WhisperRef --depth 1
    git checkout $WhisperRef
    git pull --ff-only
  } finally {
    Pop-Location
  }
}

if (Test-Path $buildDir) {
  Remove-Item -Recurse -Force $buildDir
}

$configureArgs = @(
  '-S', $srcDir,
  '-B', $buildDir,
  '-G', 'Ninja',
  "-DCMAKE_MAKE_PROGRAM=$ninjaExe",
  "-DCMAKE_TOOLCHAIN_FILE=$toolchainFile",
  "-DANDROID_ABI=$AndroidAbi",
  "-DANDROID_PLATFORM=$AndroidPlatform",
  '-DANDROID_STL=c++_static',
  '-DCMAKE_BUILD_TYPE=Release',
  '-DBUILD_SHARED_LIBS=OFF',
  '-DGGML_STATIC=ON',
  '-DGGML_OPENMP=OFF',
  '-DWHISPER_BUILD_TESTS=OFF',
  '-DWHISPER_BUILD_EXAMPLES=ON',
  '-DWHISPER_BUILD_SERVER=OFF',
  '-DWHISPER_BUILD_CURL=OFF'
)

& $cmakeExe @configureArgs

if ($LASTEXITCODE -ne 0) { throw 'cmake configure failed' }

& $cmakeExe --build $buildDir --config Release --target whisper-cli
if ($LASTEXITCODE -ne 0) { throw 'cmake build failed (target whisper-cli)' }

$candidate = Join-Path $buildDir 'bin\whisper-cli'
if (-not (Test-Path $candidate)) {
  $found = Get-ChildItem -Path $buildDir -Recurse -File -Filter 'whisper-cli*' | Select-Object -First 1
  if ($null -eq $found) {
    throw "could not find built whisper-cli under $buildDir"
  }
  $candidate = $found.FullName
}

New-Item -ItemType Directory -Force -Path $assetDir | Out-Null
Copy-Item -LiteralPath $candidate -Destination $outputPath -Force

New-Item -ItemType Directory -Force -Path $jniLibDir | Out-Null
# run-time executable path used by Android service:
# place whisper-cli in app native lib dir as libwhisper_cli.so
Copy-Item -LiteralPath $candidate -Destination (Join-Path $jniLibDir 'libwhisper_cli.so') -Force

$sharedLibs = @(
  @{ Name = 'libwhisper.so'; Path = (Join-Path $buildDir 'src\libwhisper.so') },
  @{ Name = 'libggml.so'; Path = (Join-Path $buildDir 'ggml\src\libggml.so') },
  @{ Name = 'libggml-base.so'; Path = (Join-Path $buildDir 'ggml\src\libggml-base.so') },
  @{ Name = 'libggml-cpu.so'; Path = (Join-Path $buildDir 'ggml\src\libggml-cpu.so') },
  @{ Name = 'libc++_shared.so'; Path = (Join-Path $ndkRoot 'toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\aarch64-linux-android\libc++_shared.so') },
  @{ Name = 'libomp.so'; Path = (Join-Path $ndkRoot 'toolchains\llvm\prebuilt\windows-x86_64\lib\clang\19\lib\linux\aarch64\libomp.so') }
)

foreach ($lib in $sharedLibs) {
  if (-not (Test-Path $lib.Path)) {
    Write-Host "optional shared library missing (static build may not need it): $($lib.Path)"
    continue
  }
  Copy-Item -LiteralPath $lib.Path -Destination (Join-Path $jniLibDir $lib.Name) -Force
}

Write-Host "Built and copied whisper-cli:"
Write-Host "Source: $candidate"
Write-Host "Asset : $outputPath"
Write-Host "JNI libs copied to: $jniLibDir"
