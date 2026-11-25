# Packages source files, without the Windows SDK, generated builds or private keys.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$output = Join-Path $projectPath 'distributie'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$archive = Join-Path $output 'Stiri-si-favorite-surse-Mac.zip'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$rootFiles = @('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'README.md', 'PRODUCT.md', 'DESIGN.md', '.gitignore', '.metadata')
$sourceFolders = @('lib', 'test', 'ios', 'android', 'web', 'scripts', 'docs', 'assets')
$sourceFiles = @(
    foreach ($name in $rootFiles) {
        $path = Join-Path $projectPath $name
        if (Test-Path -LiteralPath $path) { Get-Item -LiteralPath $path }
    }
    foreach ($name in $sourceFolders) {
        $path = Join-Path $projectPath $name
        if (Test-Path -LiteralPath $path) { Get-ChildItem -LiteralPath $path -File -Recurse -Force }
    }
    Get-ChildItem -LiteralPath $projectPath -Filter '*.cmd' -File
)
$stream = [IO.File]::Open($archive, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
$zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($projectPath.Length + 1).Replace('\', '/')
        if ($relative -match '(^|/)(\.git|\.gradle|\.cxx|\.symlinks|Pods|ephemeral|xcuserdata|build)(/|$)') { continue }
        if ($relative -match '(^|/)(local\.properties|key\.properties|Generated\.xcconfig|flutter_export_environment\.sh|GeneratedPluginRegistrant\.[hm]|\.DS_Store)$') { continue }
        if ($relative -match '\.(jks|keystore|p12|mobileprovision)$') { continue }
        if ($relative -match '^ios/Flutter/(App\.framework|Flutter\.framework|Flutter\.podspec|flutter_assets)(/|$)') { continue }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, "appstiri/$relative", [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally {
    $zip.Dispose()
}
Write-Host "Surse pentru Mac: $archive"
Write-Host 'Dezarhiveaza pe Mac, apoi urmeaza docs/INSTALARE-TELEFON.md.'
