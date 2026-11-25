param(
    [string]$DeviceId,
    [string]$SdkPath,
    [ValidateSet('debug', 'profile', 'release')][string]$Mode = 'debug'
)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'android-environment.ps1') -SdkPath $SdkPath
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter nu este în PATH.'
}
Push-Location -LiteralPath $projectPath
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Instalarea dependențelor a eșuat.' }
    if (-not $DeviceId) {
        $detectedDevices = (& flutter devices --machine) | ConvertFrom-Json
        $androidDevices = @($detectedDevices | Where-Object { $_.targetPlatform -like 'android-*' })
        if ($androidDevices.Count -eq 0) {
            throw 'Nu este conectat niciun Android. Pornește emulatorul sau conectează telefonul cu USB debugging activat.'
        }
        if ($androidDevices.Count -gt 1) {
            $androidDevices | Select-Object name, id | Format-Table
            throw 'Sunt mai multe dispozitive Android. Rulează din nou cu -DeviceId și ID-ul dorit.'
        }
        $DeviceId = $androidDevices[0].id
    }
    & flutter run "--$Mode" -d $DeviceId --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Pornirea Android a eșuat. Verifică flutter doctor -v și README.md.' }
} finally {
    Pop-Location
}
