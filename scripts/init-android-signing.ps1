# Creates the persistent private signing key once. Never overwrites an existing key.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'android-environment.ps1')
$keyPath = Join-Path $projectPath 'android/upload-keystore.jks'
$propertiesPath = Join-Path $projectPath 'android/key.properties'
$hasKey = Test-Path -LiteralPath $keyPath
$hasProperties = Test-Path -LiteralPath $propertiesPath
if ($hasKey -and $hasProperties) {
    Write-Host 'Folosesc semnatura Android existenta.'
    return
}
if ($hasKey -or $hasProperties) {
    throw 'Exista doar unul dintre upload-keystore.jks si key.properties. Restaureaza perechea din backup; nu se genereaza o cheie noua.'
}

$randomBytes = New-Object byte[] 32
$random = [Security.Cryptography.RandomNumberGenerator]::Create()
try { $random.GetBytes($randomBytes) } finally { $random.Dispose() }
$password = -join ($randomBytes | ForEach-Object { $_.ToString('x2') })
$oldPassword = $env:APPSTIRI_KEYSTORE_PASSWORD
try {
    $env:APPSTIRI_KEYSTORE_PASSWORD = $password
    & (Join-Path $env:JAVA_HOME 'bin/keytool.exe') -genkeypair -keystore $keyPath -storetype JKS -alias appstiri -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=Stiri si favorite' -storepass:env APPSTIRI_KEYSTORE_PASSWORD -keypass:env APPSTIRI_KEYSTORE_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw 'Generarea semnaturii Android a esuat.' }
    $properties = "storePassword=$password`nkeyPassword=$password`nkeyAlias=appstiri`nstoreFile=upload-keystore.jks`n"
    [IO.File]::WriteAllText($propertiesPath, $properties, [Text.UTF8Encoding]::new($false))
} finally {
    $env:APPSTIRI_KEYSTORE_PASSWORD = $oldPassword
}
Write-Host 'Semnatura a fost creata. Pastreaza un backup privat al android/upload-keystore.jks si android/key.properties.'
