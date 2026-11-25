# The drawing below is the editable source of the launcher icon. No external packages.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing

$master = [Drawing.Bitmap]::new(1024, 1024, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
$canvas = [Drawing.Graphics]::FromImage($master)
$canvas.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$blue = [Drawing.ColorTranslator]::FromHtml('#1565C0')
$paper = [Drawing.SolidBrush]::new([Drawing.Color]::White)
$ink = [Drawing.SolidBrush]::new($blue)
$gold = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#FFCA28'))
$outline = [Drawing.Pen]::new($blue, 18)
$outline.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
try {
    $canvas.Clear($blue)
    # Keep the newspaper and star inside the central safe area of maskable icons.
    $canvas.FillRectangle($paper, 254, 256, 516, 504)
    $canvas.FillRectangle($ink, 296, 302, 430, 76)
    $canvas.FillRectangle($ink, 296, 420, 158, 150)
    $canvas.FillRectangle($ink, 490, 420, 236, 24)
    $canvas.FillRectangle($ink, 490, 482, 236, 24)
    $canvas.FillRectangle($ink, 490, 544, 150, 24)
    $canvas.FillRectangle($ink, 296, 614, 216, 24)
    $canvas.FillRectangle($ink, 296, 678, 216, 24)
    $star = [Drawing.PointF[]]::new(10)
    for ($i = 0; $i -lt 10; $i++) {
        $angle = -[Math]::PI / 2 + $i * [Math]::PI / 5
        $radius = if ($i % 2 -eq 0) { 112 } else { 51 }
        $star[$i] = [Drawing.PointF]::new([single](650 + [Math]::Cos($angle) * $radius), [single](665 + [Math]::Sin($angle) * $radius))
    }
    $canvas.FillPolygon($gold, $star)
    $canvas.DrawPolygon($outline, $star)
    $numbers = [Globalization.CultureInfo]::InvariantCulture
    $starPath = 'M' + (($star | ForEach-Object { $_.X.ToString('0.###', $numbers) + ',' + $_.Y.ToString('0.###', $numbers) }) -join ' L') + ' Z'
    $vectorPath = Join-Path $projectPath 'android/app/src/main/res/drawable/ic_launcher_foreground.xml'
    $vector = @"
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="1024" android:viewportHeight="1024">
    <group android:pivotX="512" android:pivotY="512" android:scaleX="0.84" android:scaleY="0.84">
    <path android:fillColor="#FFFFFF" android:pathData="M254,256 H770 V760 H254 Z" />
    <path android:fillColor="#1565C0" android:pathData="M296,302 h430 v76 h-430 Z M296,420 h158 v150 h-158 Z M490,420 h236 v24 h-236 Z M490,482 h236 v24 h-236 Z M490,544 h150 v24 h-150 Z M296,614 h216 v24 h-216 Z M296,678 h216 v24 h-216 Z" />
    <path android:fillColor="#FFCA28" android:strokeColor="#1565C0" android:strokeWidth="18" android:strokeLineJoin="round" android:pathData="$starPath" />
    </group>
</vector>
"@
    [IO.File]::WriteAllText($vectorPath, $vector, [Text.UTF8Encoding]::new($false))
} finally {
    $canvas.Dispose()
    $paper.Dispose()
    $ink.Dispose()
    $gold.Dispose()
    $outline.Dispose()
}

function Save-Icon([string]$RelativePath, [int]$Size) {
    $path = Join-Path $projectPath $RelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    $bitmap = [Drawing.Bitmap]::new($Size, $Size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($master, 0, 0, $Size, $Size)
        $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

try {
    Save-Icon 'assets/branding/app-icon.png' 1024
    $android = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
    foreach ($density in $android.Keys) {
        Save-Icon "android/app/src/main/res/mipmap-$density/ic_launcher.png" $android[$density]
    }
    $iconFolder = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    $catalog = Get-Content -LiteralPath (Join-Path $projectPath "$iconFolder/Contents.json") -Raw | ConvertFrom-Json
    foreach ($entry in $catalog.images) {
        $baseSize = [double]::Parse(($entry.size -split 'x')[0], [Globalization.CultureInfo]::InvariantCulture)
        $scale = [int]($entry.scale -replace 'x', '')
        Save-Icon "$iconFolder/$($entry.filename)" ([int]($baseSize * $scale))
    }
    foreach ($size in @(192, 512)) {
        Save-Icon "web/icons/Icon-$size.png" $size
        Save-Icon "web/icons/Icon-maskable-$size.png" $size
    }
    Save-Icon 'web/favicon.png' 32
} finally {
    $master.Dispose()
}
Write-Host 'Iconitele Android, iOS si web au fost generate din acelasi desen.'
