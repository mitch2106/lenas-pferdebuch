Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

$projectRoot = Split-Path -Parent $PSScriptRoot
$epubDir = Join-Path $projectRoot "epub_band2"
$epubPath = Join-Path $projectRoot "ebooks/Lena_und_das_Fohlen_aus_Mondlicht.epub"

if (Test-Path $epubPath) { Remove-Item $epubPath }

$zip = [System.IO.Compression.ZipFile]::Open($epubPath, 'Create')

# mimetype must be first, uncompressed
$entry = $zip.CreateEntry('mimetype', [System.IO.Compression.CompressionLevel]::NoCompression)
$writer = New-Object System.IO.StreamWriter($entry.Open())
$writer.Write('application/epub+zip')
$writer.Close()

# Add all other files
Get-ChildItem -Path $epubDir -Recurse -File | Where-Object { $_.Name -ne 'mimetype' } | ForEach-Object {
    $rel = $_.FullName.Substring($epubDir.Length + 1).Replace('\', '/')
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
}

$zip.Dispose()
Write-Host "EPUB erstellt: $epubPath"
