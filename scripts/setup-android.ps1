# Run interactively from Windows. Does not install an emulator or alter the system PATH.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$sdkPath = Join-Path $projectPath '.tooling/android-sdk'
. (Join-Path $PSScriptRoot 'android-environment.ps1') -SdkPath $sdkPath

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter nu este in PATH. Vezi docs/INSTALARE-TELEFON.md.'
}
$sdkManager = Join-Path $sdkPath 'cmdline-tools/latest/bin/sdkmanager.bat'
if (-not (Test-Path -LiteralPath $sdkManager)) {
    $downloads = Join-Path $projectPath '.tooling/downloads'
    New-Item -ItemType Directory -Force -Path $downloads | Out-Null
    $archive = Join-Path $downloads 'commandlinetools-win-15859902_latest.zip'
    $expectedHash = '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'
    if (-not (Test-Path -LiteralPath $archive)) {
        Write-Host 'Descarc uneltele Android de la Google (aproximativ 156 MB)...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        $partial = "$archive.partial"
        Invoke-WebRequest -UseBasicParsing -Uri 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip' -OutFile $partial
        if ((Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash -ne $expectedHash) {
            throw "Verificarea SHA256 a esuat. Nu se executa arhiva: $partial"
        }
        Move-Item -LiteralPath $partial -Destination $archive -Force
    }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedHash) {
        throw "Arhiva Android nu are suma SHA256 asteptata: $archive"
    }
    $unpacked = Join-Path $downloads 'commandline-unpacked'
    Expand-Archive -LiteralPath $archive -DestinationPath $unpacked -Force
    $latest = Join-Path $sdkPath 'cmdline-tools/latest'
    New-Item -ItemType Directory -Force -Path $latest | Out-Null
    Copy-Item -Path (Join-Path $unpacked 'cmdline-tools/*') -Destination $latest -Recurse -Force
}

Write-Host 'Citeste licentele Android si raspunde la intrebarile uneltei Google.'
& $sdkManager "--sdk_root=$sdkPath" --licenses
if ($LASTEXITCODE -ne 0) { throw 'Licentele Android nu au fost acceptate. Configurarea s-a oprit.' }

Write-Host 'Instalez SDK 36, Build Tools 36.0.0 si NDK. Prima instalare poate dura si ocupa cativa GB.'
& $sdkManager "--sdk_root=$sdkPath" 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358' 'cmake;3.22.1'
if ($LASTEXITCODE -ne 0) { throw 'Instalarea Android SDK a esuat. Verifica mesajul Google de mai sus.' }

& flutter doctor -v
if ($LASTEXITCODE -ne 0) { throw 'flutter doctor a raportat o eroare. Verifica sectiunea Android toolchain.' }
Write-Host 'Uneltele Android sunt instalate. Urmatorul pas: Genereaza-Android.cmd.'
