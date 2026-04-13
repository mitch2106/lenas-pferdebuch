# Lenas Pferdebuch – Sonnenweide-Abenteuer

Kinderbuch-Reihe mit interaktiver Web-App, EPUB-Versionen und Print-Materialien.

**Live:** https://mitch2106.github.io/lenas-pferdebuch/interaktiv.html

## Bände

| Band | Titel | Status |
|------|-------|--------|
| 1 | Lena und das Geheimnis der silbernen Hufspur | ✅ Fertig |
| 2 | Lena und das Fohlen aus Mondlicht | ✅ Geschichte fertig (Bilder folgen) |
| 3 | Lena und der Schatten im Wald | 🔮 In Planung |

## Ordnerstruktur

```
.
├── interaktiv.html        # Interaktive Web-App (GitHub Pages)
├── README.md
├── stories/               # Markdown-Quelldateien
│   ├── geschichte.md
│   └── geschichte_band2.md
├── prompts/               # Bild-Prompts für KI-Generierung
│   ├── bild-prompts.md            # Band 1 Einzelprompts
│   ├── bild-prompts-neu.md        # Sammelkarten + Adventure
│   ├── bild-prompts-band2.md      # Band 2 Master-Prompt
│   └── perplexity-prompt.md       # Perplexity Mega-Prompt
├── print/                 # Druckbare HTML-Versionen
│   ├── hauptbuch.html
│   ├── cover.html
│   ├── hofkarte.html
│   ├── raetselheft.html
│   ├── steckbriefkarten.html
│   └── elternuebersicht.html
├── scripts/               # Build-Skripte
│   ├── build_epub_quick.ps1       # Band 1 EPUB bauen
│   ├── build_epub_band2.ps1       # Band 2 EPUB bauen
│   ├── build_epub.mjs             # Node-Variante
│   └── build_epub.py              # Python-Variante
├── ebooks/                # Fertige EPUB-Dateien für Kindle
│   ├── Lena_und_das_Geheimnis_der_silbernen_Hufspur.epub
│   └── Lena_und_das_Fohlen_aus_Mondlicht.epub
├── epub/                  # EPUB-Quelle Band 1 (XHTML, OPF, CSS)
├── epub_band2/            # EPUB-Quelle Band 2
├── bilder/                # Bild-Assets (Originale + web/ JPGs)
└── pdf/                   # Generierte PDFs (gitignored)
```

## EPUB neu bauen

```powershell
# Band 1
powershell -ExecutionPolicy Bypass -File scripts/build_epub_quick.ps1

# Band 2
powershell -ExecutionPolicy Bypass -File scripts/build_epub_band2.ps1
```

Die fertigen `.epub`-Dateien landen in `ebooks/`.

## EPUB an Kindle senden

1. Über E-Mail an die persönliche `@kindle.com`-Adresse als Anhang
2. Über [amazon.de/sendtokindle](https://amazon.de/sendtokindle) – Drag & Drop
3. Per USB-Kabel in den `documents/`-Ordner des Kindle kopieren
