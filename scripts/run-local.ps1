param([ValidateRange(1024, 65535)][int]$Port = 5173)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter nu este în PATH. Instalează Flutter și redeschide terminalul.'
}
Push-Location -LiteralPath $projectPath
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Instalarea dependențelor a eșuat.' }
    Write-Host "Deschide http://localhost:$Port în browser. Oprește serverul cu Ctrl+C."
    & flutter run -d web-server --web-hostname 127.0.0.1 --web-port $Port --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Serverul nu a pornit. Verifică dacă portul este liber.' }
} finally {
    Pop-Location
}
