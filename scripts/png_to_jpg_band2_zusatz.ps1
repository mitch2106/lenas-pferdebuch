Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$epubImgDir = Join-Path $projectRoot "epub_band2/OEBPS/images"
$webDir = Join-Path $projectRoot "bilder/band2/web"

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 82L)

$maxDim = 1400

Get-ChildItem -Path $epubImgDir -Filter "*zusatz*.png" | ForEach-Object {
    $name = $_.BaseName
    $jpgEpub = Join-Path $epubImgDir "$name.jpg"
    $jpgWeb  = Join-Path $webDir "$name.jpg"

    Write-Host "Konvertiere $($_.Name) ..."

    $img = [System.Drawing.Image]::FromFile($_.FullName)

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

    $img.Save($jpgEpub, $jpegCodec, $encoderParams)
    $img.Save($jpgWeb, $jpegCodec, $encoderParams)
    $img.Dispose()

    $size = [Math]::Round((Get-Item $jpgEpub).Length / 1KB, 1)
    Write-Host "  -> $name.jpg ($size KB)"
}

Get-ChildItem -Path $epubImgDir -Filter "*zusatz*.png" | Remove-Item

$total = (Get-ChildItem -Path $epubImgDir -Filter "*.jpg" | Measure-Object -Property Length -Sum).Sum
Write-Host "`nGesamt (alle JPGs im EPUB-Images): $([Math]::Round($total / 1MB, 2)) MB"
