# Dot-source this file so these variables apply only to the current process.
param([string]$SdkPath)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot

if (-not $env:JAVA_HOME) {
    if ($env:JavaHome -and (Test-Path -LiteralPath (Join-Path $env:JavaHome 'bin/java.exe'))) {
        $env:JAVA_HOME = $env:JavaHome
    } else {
        $studioJdk = Join-Path $env:ProgramFiles 'Android/Android Studio/jbr'
        if (Test-Path -LiteralPath (Join-Path $studioJdk 'bin/java.exe')) {
            $env:JAVA_HOME = $studioJdk
        }
    }
}
if (-not $env:JAVA_HOME -or -not (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin/java.exe'))) {
    throw 'Este necesar JDK 21. Instaleaza Android Studio sau seteaza JAVA_HOME la folderul JDK 21.'
}
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:PATH

if (-not $SdkPath) {
    $candidates = @(
        (Join-Path $projectPath '.tooling/android-sdk'),
        $env:ANDROID_HOME,
        $env:ANDROID_SDK_ROOT,
        (Join-Path $env:LOCALAPPDATA 'Android/Sdk')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate 'platform-tools/adb.exe'))) {
            $SdkPath = $candidate
            break
        }
    }
}
if ($SdkPath) {
    $env:ANDROID_HOME = [IO.Path]::GetFullPath($SdkPath)
    $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
    $env:PATH = (Join-Path $env:ANDROID_HOME 'platform-tools') + ';' + $env:PATH
}
$env:GRADLE_USER_HOME = Join-Path $projectPath '.tooling/gradle'
