# The drawing below is the editable source of the launcher icon. No external packages.
[CmdletBinding()]
param([switch]$AndroidOnly)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing

function Save-AndroidIcons {
    $source = Join-Path $projectPath 'assets/branding/unitbv.png'
    $resources = Join-Path $projectPath 'android/app/src/main/res'
    $drawable = Join-Path $resources 'drawable-nodpi'
    New-Item -ItemType Directory -Path $drawable -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination (Join-Path $drawable 'ic_launcher_mark.png') -Force

    $mark = [Drawing.Image]::FromFile($source)
    $background = [Drawing.ColorTranslator]::FromHtml('#0064A0')
    $sizes = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
    try {
        foreach ($density in $sizes.Keys) {
            $size = $sizes[$density]
            $edge = [int]($size * .58)
            $inset = [int](($size - $edge) / 2)
            $bitmap = [Drawing.Bitmap]::new($size, $size)
            $graphics = [Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear($background)
                $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.DrawImage($mark, $inset, $inset, $edge, $edge)
                $bitmap.Save((Join-Path $resources "mipmap-$density/ic_launcher.png"), [Drawing.Imaging.ImageFormat]::Png)
            } finally {
                $graphics.Dispose()
                $bitmap.Dispose()
            }
        }
    } finally {
        $mark.Dispose()
    }
}

Save-AndroidIcons
if ($AndroidOnly) { return }

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
Write-Host 'Iconitele Android, iOS si web au fost generate.'
