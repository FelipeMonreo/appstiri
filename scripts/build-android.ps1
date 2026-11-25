[CmdletBinding()]
param([ValidateSet('release', 'debug')][string]$Mode = 'release', [string]$SdkPath)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'android-environment.ps1') -SdkPath $SdkPath
if (-not $env:ANDROID_HOME -or -not (Test-Path -LiteralPath (Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe'))) {
    throw 'Android SDK nu este pregatit. Porneste Configureaza-Android.cmd sau instaleaza SDK-ul cu Android Studio.'
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter nu este in PATH.' }

Push-Location -LiteralPath $projectPath
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Instalarea dependentelor Flutter a esuat.' }
    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Analiza codului a esuat.' }
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Testele au esuat. Nu se distribuie aceasta versiune.' }
    if ($Mode -eq 'release') { & (Join-Path $PSScriptRoot 'init-android-signing.ps1') }
    & flutter build apk "--$Mode" --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Compilarea APK a esuat. Citeste eroarea de mai sus.' }

    $output = Join-Path $projectPath 'distributie/android'
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    $apk = Join-Path $projectPath "build/app/outputs/flutter-apk/app-$Mode.apk"
    $versionLine = Get-Content -LiteralPath (Join-Path $projectPath 'pubspec.yaml') | Where-Object { $_ -match '^version:\s*\S+' } | Select-Object -First 1
    $version = ($versionLine -replace '^version:\s*', '').Trim()
    if ($version -notmatch '^\d+\.\d+\.\d+\+\d+$') { throw 'Versiunea din pubspec.yaml trebuie sa aiba forma 1.0.0+1.' }
    $destination = Join-Path $output "Stiri-si-favorite-$version-$Mode.apk"
    Copy-Item -LiteralPath $apk -Destination $destination -Force
    $hash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText("$destination.sha256", "$hash  $([IO.Path]::GetFileName($destination))`n", [Text.Encoding]::ASCII)
    Write-Host "APK pregatit: $destination"
    Write-Host 'Transfera APK-ul pe Android si deschide-l pentru instalare. Vezi docs/INSTALARE-TELEFON.md.'
} finally {
    Pop-Location
}
