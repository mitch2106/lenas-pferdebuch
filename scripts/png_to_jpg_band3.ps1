Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $projectRoot "epub_band3/OEBPS/images"

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 82L)

$maxDim = 1400

Get-ChildItem -Path $srcDir -Filter "*.png" | ForEach-Object {
    $name = $_.BaseName
    $jpgPath = Join-Path $srcDir "$name.jpg"

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

    $img.Save($jpgPath, $jpegCodec, $encoderParams)
    $img.Dispose()

    $size = [Math]::Round((Get-Item $jpgPath).Length / 1KB, 1)
    Write-Host "  -> $name.jpg ($size KB)"
}

# PNGs loeschen, nachdem alle JPGs geschrieben sind
Get-ChildItem -Path $srcDir -Filter "*.png" | Remove-Item

$total = (Get-ChildItem -Path $srcDir -Filter "*.jpg" | Measure-Object -Property Length -Sum).Sum
Write-Host "`nGesamtgroesse: $([Math]::Round($total / 1MB, 2)) MB"
