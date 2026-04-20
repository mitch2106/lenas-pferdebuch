param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$srcMd = Join-Path $ProjectRoot 'band3/manuskript/geschichte_band3.md'
$epubRoot = Join-Path $ProjectRoot 'epub_band3'
$oebps = Join-Path $epubRoot 'OEBPS'
$metaInf = Join-Path $epubRoot 'META-INF'
$images = Join-Path $oebps 'images'
$stylesPath = Join-Path $oebps 'styles.css'

if (Test-Path $epubRoot) {
    Remove-Item $epubRoot -Recurse -Force
}

New-Item -ItemType Directory -Force $metaInf | Out-Null
New-Item -ItemType Directory -Force $images | Out-Null

Set-Content -Path (Join-Path $epubRoot 'mimetype') -Value 'application/epub+zip' -Encoding ascii -NoNewline

$containerXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
'@
Set-Content -Path (Join-Path $metaInf 'container.xml') -Value $containerXml -Encoding UTF8

Copy-Item (Join-Path $ProjectRoot 'epub_band2/OEBPS/styles.css') $stylesPath -Force

$extraCss = @'

/* Band 3 refinements */
.front-matter-image,
.scene-image {
  text-align: center;
  margin: 1.4em 0 1.1em;
}

.front-matter-image img,
.scene-image img {
  max-width: 100%;
  height: auto;
}

.scene-image.compact {
  margin-top: 1.1em;
  margin-bottom: 0.8em;
}

.scene-image + p {
  text-indent: 0;
}

.ending-note {
  text-align: center;
  margin-top: 2.2em;
}

.ending-note p {
  text-indent: 0;
  font-style: italic;
}
'@
Add-Content -Path $stylesPath -Value $extraCss -Encoding UTF8

$imageMap = [ordered]@{
    'cover_band3_final.png'              = 'band3/bilder/final/cover_band3_final.png'
    'kap01_band3_ankunft.png'            = 'band3/bilder/final/kap01_ankunft_bmw_x5.png'
    'kap01_band3_sturmwind.png'          = 'band3/bilder/final/kap01_stall_sturmwind.png'
    'kap01_band3_mondfohlen.png'         = 'band3/bilder/final/kap01_mondfohlen_waldrand.png'
    'kap02_band3_spuren.png'             = 'band3/bilder/final/kap02_spuren_im_schnee.png'
    'kap02_band3_stall.png'              = 'band3/bilder/final/kap02_sturmwind_unruhe.png'
    'kap02_band3_waldrand.png'           = 'band3/bilder/final/kap02_schatten_am_waldrand.png'
    'kap03_band3_schatten.png'           = 'band3/bilder/final/kap03_schatten_im_wald.png'
    'kap03_band3_waechter.png'           = 'band3/bilder/final/kap03_mondfohlen_und_w*chter.png'
    'kap04_band3_kueche.png'             = 'band3/bilder/final/kap04_kueche_geschichtenabend.png'
    'kap04_band3_erinnerung.png'         = 'band3/bilder/final/kap04_erinnerungsszene_korrigiert.png'
    'kap05_band3_stein.png'              = 'band3/bilder/final/kap05_stein_im_schnee.png'
    'kap05_band3_ruf.png'                = 'band3/bilder/final/kap05_mondfohlen_wird_gerufen.png'
    'kap06_band3_lichtung.png'           = 'band3/bilder/final/kap06_lichtung_entdeckt.png'
    'kap06_band3_waechter.png'           = 'band3/bilder/final/kap06_mondfohlen_lichtung_waechter.png'
    'kap07_band3_dachboden.png'          = 'band3/bilder/final/kap07_dachboden_suche.png'
    'kap07_band3_truhe.png'              = 'band3/bilder/final/kap07_truhe_und_heft.png'
    'kap08_band3_holz.png'               = 'band3/bilder/final/kap08_lena_und_papa_mit_holz.png'
    'kap08_band3_stall.png'              = 'band3/bilder/final/kap08_sturmwind_unruhiger_stall.png'
    'kap09_band3_zeichen.png'            = 'band3/bilder/final/kap09_anja_erklaert_zeichen.png'
    'kap09_band3_mondfohlen.png'         = 'band3/bilder/final/kap09_mondfohlen_zeigt_den_weg.png'
    'kap10_band3_sturmnacht.png'         = 'band3/bilder/final/kap10_sturmnacht_aufbruch.png'
    'kap11_band3_waechter.png'           = 'band3/bilder/final/kap11_lichtung_wachter_und_mondfohlen.png'
    'kap12_band3_morgen.png'             = 'band3/bilder/final/kap12_stiller_morgen.png'
}

foreach ($target in $imageMap.Keys) {
    Copy-Item (Join-Path $ProjectRoot $imageMap[$target]) (Join-Path $images $target) -Force
}

function Escape-XmlText([string]$Text) {
    [System.Security.SecurityElement]::Escape($Text)
}

function New-ImageBlock([string]$FileName, [string]$AltText, [string]$CssClass = 'scene-image') {
    @"
  <div class="$CssClass">
    <img src="images/$FileName" alt="$(Escape-XmlText $AltText)"/>
  </div>
"@
}

$lines = Get-Content $srcMd -Encoding UTF8
$chapters = @()
$current = $null

foreach ($line in $lines) {
    if ($line -match '^## Kapitel\s+(\d+)\s+-\s+(.+)$') {
        if ($current) {
            $chapters += [pscustomobject]$current
        }
        $current = @{
            Number = [int]$matches[1]
            Title = $matches[2].Trim()
            Paragraphs = New-Object 'System.Collections.Generic.List[string]'
        }
        continue
    }

    if (-not $current -or $line -eq '---') {
        continue
    }

    $current.Paragraphs.Add($line)
}

if ($current) {
    $chapters += [pscustomobject]$current
}

$chapterImageNames = @{
    1 = 'kap01_band3_ankunft.png'
    2 = 'kap02_band3_spuren.png'
    3 = 'kap03_band3_schatten.png'
    4 = 'kap04_band3_kueche.png'
    5 = 'kap05_band3_stein.png'
    6 = 'kap06_band3_lichtung.png'
    7 = 'kap07_band3_dachboden.png'
    8 = 'kap08_band3_holz.png'
    9 = 'kap09_band3_zeichen.png'
    10 = 'kap10_band3_sturmnacht.png'
    11 = 'kap11_band3_waechter.png'
    12 = 'kap12_band3_morgen.png'
}

$chapterImageAlt = @{
    1 = 'Lena kommt im Schnee auf Hof Sonnenweide an'
    2 = 'Seltsame Spuren im Schnee'
    3 = 'Der Schatten zwischen den Baeumen'
    4 = 'Abend in der warmen Kueche von Sonnenweide'
    5 = 'Der alte Stein unter Schnee und Eis'
    6 = 'Die verborgene Lichtung im Winterwald'
    7 = 'Suche nach alten Hinweisen auf dem Dachboden'
    8 = 'Lena und ihr Papa auf dem verschneiten Hof'
    9 = 'Anja erkennt das alte Zeichen'
    10 = 'Aufbruch in der Sturmnacht'
    11 = 'Mondfohlen und letzter Waechter auf der Lichtung'
    12 = 'Ein stiller Morgen auf Sonnenweide'
}

$chapterExtraImages = @{
    1 = @(
        @{ After = 42; File = 'kap01_band3_sturmwind.png'; Alt = 'Lena begruesst Sturmwind im Stall' },
        @{ After = 101; File = 'kap01_band3_mondfohlen.png'; Alt = 'Das Mondfohlen zeigt sich am Waldrand'; CssClass = 'scene-image compact' }
    )
    2 = @(
        @{ After = 31; File = 'kap02_band3_stall.png'; Alt = 'Sturmwind ist im Stall unruhig' },
        @{ After = 74; File = 'kap02_band3_waldrand.png'; Alt = 'Ein dunkler Umriss zeigt sich am Waldrand'; CssClass = 'scene-image compact' }
    )
    3 = @(
        @{ After = 58; File = 'kap03_band3_waechter.png'; Alt = 'Mondfohlen und Waechter im verschneiten Wald' }
    )
    4 = @(
        @{ After = 44; File = 'kap04_band3_erinnerung.png'; Alt = 'Die alte Erinnerung an den Winterwaechter' }
    )
    5 = @(
        @{ After = 61; File = 'kap05_band3_ruf.png'; Alt = 'Das Mondfohlen wird in Richtung Wald gerufen' }
    )
    6 = @(
        @{ After = 55; File = 'kap06_band3_waechter.png'; Alt = 'Auf der Lichtung begegnen sich Mondfohlen und Waechter' }
    )
    7 = @(
        @{ After = 48; File = 'kap07_band3_truhe.png'; Alt = 'Die geoeffnete Truhe mit Heft und alten Papieren' }
    )
    8 = @(
        @{ After = 47; File = 'kap08_band3_stall.png'; Alt = 'Sturmwind ist in der Nacht erneut unruhig' }
    )
    9 = @(
        @{ After = 39; File = 'kap09_band3_mondfohlen.png'; Alt = 'Das Mondfohlen zeigt Lena und Anja den Weg' }
    )
}

foreach ($chapter in $chapters) {
    $paragraphs = New-Object 'System.Collections.Generic.List[string]'
    $buffer = New-Object 'System.Collections.Generic.List[string]'

    foreach ($entry in $chapter.Paragraphs) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            if ($buffer.Count -gt 0) {
                $paragraphs.Add(($buffer -join ' '))
                $buffer.Clear()
            }
        }
        else {
            $buffer.Add($entry.Trim())
        }
    }

    if ($buffer.Count -gt 0) {
        $paragraphs.Add(($buffer -join ' '))
    }

    $bodyBlocks = New-Object 'System.Collections.Generic.List[string]'
    $bodyBlocks.Add((New-ImageBlock -FileName $chapterImageNames[$chapter.Number] -AltText $chapterImageAlt[$chapter.Number] -CssClass 'chapter-image'))

    for ($i = 0; $i -lt $paragraphs.Count; $i++) {
        $cls = if ($i -eq 0) { ' class="first"' } else { '' }
        $bodyBlocks.Add(('  <p{0}>{1}</p>' -f $cls, (Escape-XmlText $paragraphs[$i])))

        if ($chapterExtraImages.ContainsKey($chapter.Number)) {
            foreach ($extra in $chapterExtraImages[$chapter.Number]) {
                if (($i + 1) -eq [int]$extra.After) {
                    $cssClass = if ($extra.ContainsKey('CssClass')) { [string]$extra.CssClass } else { 'scene-image' }
                    $bodyBlocks.Add((New-ImageBlock -FileName $extra.File -AltText $extra.Alt -CssClass $cssClass))
                }
            }
        }
    }

    if ($chapter.Number -eq 12) {
        $bodyBlocks.Add(@'
  <div class="ending-note">
    <p>Das Abenteuer auf Sonnenweide geht weiter.</p>
  </div>
'@)
    }

    $titleText = "Kapitel $($chapter.Number) - $($chapter.Title)"

    $chapterXhtml = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="de" lang="de">
<head>
  <meta charset="UTF-8"/>
  <title>$(Escape-XmlText $titleText)</title>
  <link rel="stylesheet" type="text/css" href="styles.css"/>
</head>
<body>
  <h2>$(Escape-XmlText $titleText)</h2>

$($bodyBlocks -join "`r`n`r`n")
</body>
</html>
"@

    Set-Content -Path (Join-Path $oebps ('chapter{0:d2}.xhtml' -f $chapter.Number)) -Value $chapterXhtml -Encoding UTF8
}

$coverXhtml = @'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="de" lang="de">
<head>
  <meta charset="UTF-8"/>
  <title>Cover</title>
  <link rel="stylesheet" type="text/css" href="styles.css"/>
  <style type="text/css">
    body { margin: 0; padding: 0; text-align: center; }
    img { max-width: 100%; max-height: 100vh; height: auto; }
  </style>
</head>
<body>
  <div>
    <img src="images/cover_band3_final.png" alt="Cover - Lena und der Schatten im Wald"/>
  </div>
</body>
</html>
'@
Set-Content -Path (Join-Path $oebps 'cover.xhtml') -Value $coverXhtml -Encoding UTF8

$titleXhtml = @'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="de" lang="de">
<head>
  <meta charset="UTF-8"/>
  <title>Lena und der Schatten im Wald</title>
  <link rel="stylesheet" type="text/css" href="styles.css"/>
</head>
<body>
  <div class="front-matter-image">
    <img src="images/cover_band3_final.png" alt="Winterliches Covermotiv von Lena und dem Mondfohlen"/>
  </div>
  <div class="title-page">
    <h1>Lena und der Schatten im Wald</h1>
    <h2>Band 3 der Sonnenweide-Abenteuer</h2>
  </div>
</body>
</html>
'@
Set-Content -Path (Join-Path $oebps 'title.xhtml') -Value $titleXhtml -Encoding UTF8

$dedicationXhtml = @'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="de" lang="de">
<head>
  <meta charset="UTF-8"/>
  <title>Widmung</title>
  <link rel="stylesheet" type="text/css" href="styles.css"/>
</head>
<body>
  <p class="dedication">F&#xFC;r Lena - und f&#xFC;r alle, die auch im Winter dem leisen Licht folgen.</p>
</body>
</html>
'@
Set-Content -Path (Join-Path $oebps 'dedication.xhtml') -Value $dedicationXhtml -Encoding UTF8

$tocItems = @(
    '      <li><a href="title.xhtml">Titel</a></li>',
    '      <li><a href="dedication.xhtml">Widmung</a></li>'
)

foreach ($chapter in $chapters) {
    $tocTitle = Escape-XmlText("Kapitel $($chapter.Number) - $($chapter.Title)")
    $tocItems += ('      <li><a href="chapter{0:d2}.xhtml">{1}</a></li>' -f $chapter.Number, $tocTitle)
}

$tocXhtml = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="de" lang="de">
<head>
  <meta charset="UTF-8"/>
  <title>Inhaltsverzeichnis</title>
  <link rel="stylesheet" type="text/css" href="styles.css"/>
</head>
<body>
  <nav epub:type="toc" id="toc">
    <h1>Inhaltsverzeichnis</h1>
    <ol>
$($tocItems -join "`r`n")
    </ol>
  </nav>
</body>
</html>
"@
Set-Content -Path (Join-Path $oebps 'toc.xhtml') -Value $tocXhtml -Encoding UTF8

$manifest = @(
    '    <item id="nav" href="toc.xhtml" media-type="application/xhtml+xml" properties="nav"/>',
    '    <item id="css" href="styles.css" media-type="text/css"/>',
    '    <item id="cover_page" href="cover.xhtml" media-type="application/xhtml+xml"/>',
    '    <item id="title" href="title.xhtml" media-type="application/xhtml+xml"/>',
    '    <item id="dedication" href="dedication.xhtml" media-type="application/xhtml+xml"/>',
    '    <item id="img_cover" href="images/cover_band3_final.png" media-type="image/png" properties="cover-image"/>'
)

foreach ($chapter in $chapters) {
    $manifest += ('    <item id="ch{0:d2}" href="chapter{0:d2}.xhtml" media-type="application/xhtml+xml"/>' -f $chapter.Number)
}

$imageIndex = 1
foreach ($imageName in $imageMap.Keys) {
    if ($imageName -eq 'cover_band3_final.png') {
        continue
    }
    $manifest += ('    <item id="img{0:d2}" href="images/{1}" media-type="image/png"/>' -f $imageIndex, $imageName)
    $imageIndex++
}

$spine = @(
    '    <itemref idref="cover_page"/>',
    '    <itemref idref="title"/>',
    '    <itemref idref="dedication"/>',
    '    <itemref idref="nav"/>'
)

foreach ($chapter in $chapters) {
    $spine += ('    <itemref idref="ch{0:d2}"/>' -f $chapter.Number)
}

$opf = @"
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="BookId" xml:lang="de">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="BookId">urn:uuid:c3d4e5f6-a7b8-9012-cdef-345678901234</dc:identifier>
    <dc:title>Lena und der Schatten im Wald</dc:title>
    <dc:language>de</dc:language>
    <dc:creator>M. Heinl</dc:creator>
    <dc:description>Band 3 der Sonnenweide-Abenteuer. In den Winterferien kehrt Lena nach Hof Sonnenweide zur&#xFC;ck. Gemeinsam mit Anja, ihrem Papa und Tante Sarah folgt sie den Spuren eines alten W&#xE4;chters im Wald, w&#xE4;hrend das Mondfohlen in seine Rolle als neuer H&#xFC;ter hineinw&#xE4;chst.</dc:description>
    <dc:subject>Kinderbuch</dc:subject>
    <dc:subject>Pferde</dc:subject>
    <dc:subject>Abenteuer</dc:subject>
    <dc:subject>Winter</dc:subject>
    <meta property="dcterms:modified">2026-04-20T00:00:00Z</meta>
  </metadata>
  <manifest>
$($manifest -join "`r`n")
  </manifest>
  <spine>
$($spine -join "`r`n")
  </spine>
</package>
"@
Set-Content -Path (Join-Path $oebps 'content.opf') -Value $opf -Encoding UTF8

Write-Output "Created $epubRoot"
