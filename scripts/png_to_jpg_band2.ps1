Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $projectRoot "bilder/band2"
$webDir = Join-Path $srcDir "web"
$epubImgDir = Join-Path $projectRoot "epub_band2/OEBPS/images"

if (-not (Test-Path $webDir)) { New-Item -ItemType Directory -Path $webDir | Out-Null }
if (-not (Test-Path $epubImgDir)) { New-Item -ItemType Directory -Path $epubImgDir | Out-Null }

# JPEG-Encoder mit Quality 82 (gut fuer Foto-Watercolor, ~300-450 KB)
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 82L)

# Maximale Breite (laengste Seite) fuer Web/EPUB
$maxDim = 1400

Get-ChildItem -Path $srcDir -Filter "*.png" | ForEach-Object {
    $name = $_.BaseName
    $jpgName = "$name.jpg"

    Write-Host "Konvertiere $($_.Name) ..."

    $img = [System.Drawing.Image]::FromFile($_.FullName)

    # Skalieren wenn noetig
    $w = $img.Width
    $h = $img.Height
    if ($w -gt $maxDim -or $h -gt $maxDim) {
        if ($w -ge $h) {
            $newW = $maxDim
            $newH = [int]($h * $maxDim / $w)
        } else {
            $newH = $maxDim
            $newW = [int]($w * $maxDim / $h)
        }
        $resized = New-Object System.Drawing.Bitmap $newW, $newH
        $g = [System.Drawing.Graphics]::FromImage($resized)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.DrawImage($img, 0, 0, $newW, $newH)
        $g.Dispose()
        $img.Dispose()
        $img = $resized
    }

    # Speichere in beide Ziele
    $webPath = Join-Path $webDir $jpgName
    $epubPath = Join-Path $epubImgDir $jpgName

    $img.Save($webPath, $jpegCodec, $encoderParams)
    $img.Save($epubPath, $jpegCodec, $encoderParams)

    $img.Dispose()

    $size = [Math]::Round((Get-Item $webPath).Length / 1KB, 1)
    Write-Host "  -> $jpgName ($size KB)"
}

Write-Host "`nAlle PNGs konvertiert."
