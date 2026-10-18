# Lector

Lector iPad: zoom multinivel (vault) + chat + Preguntador (SRS) + highlights tipo Readwise. Motor **Readium** (SPM) + PDFKit.

Ver [PRODUCT.md](PRODUCT.md) y [SCAFFOLDS.md](SCAFFOLDS.md).

## Abrir / compilar (Mac + Xcode)

```bash
cd apps/lector
# Opción A: proyecto ya generado
open Lector.xcodeproj

# Opción B: regenerar con XcodeGen
xcodegen generate
open Lector.xcodeproj
```

- Destino: **iPad** (device family 2), iOS 17+
- Bundle ID: `com.horacioeps.lector`
- Team: `WMY552P2HR`
- SPM: `readium/swift-toolkit` ≥ 3.11.1 → `ReadiumShared` + `ReadiumStreamer`

La primera resolución de paquetes puede tardar.

## v0.1 incluido

| Pieza | Estado |
|-------|--------|
| Biblioteca + import PDF/EPUB/MD/TXT | sí |
| Libro semilla `seed_book.md` | sí |
| Zoom extractivo + **enriquecimiento LLM** | sí |
| Chat anclado al nodo con **OpenAI** (fallback local) | sí |
| Preguntador SM-2 + **generación LLM** (escaletas / pistas) | sí |
| Ajustes: API key en Keychain | sí |
| Highlights + export Markdown | sí |
| Extracción EPUB vía Readium | sí |
| PDF páginas (PDFKit) | sí |
| Código original Cursor «TEDX Almería 2026» (Mac) | no recuperable desde este cloud (sin placement al worker M4) |
| Zotero / Books / Kindle DRM | pendiente |
| EPUBNavigator UI nativa Readium | pendiente |

### OpenAI

1. Abre Lector → ⚙ Ajustes  
2. Pega API key → modelo (default `gpt-4o-mini`) → Guardar  
3. Al abrir un libro, el zoom pide resúmenes LLM; el chat y «Generar con LLM» del Preguntador la usan.

## Estructura

```
Lector/
  LectorApp.swift
  Models/
  Services/   # Library, ZoomTree, ReadiumBridge, Chat, Preguntador, Highlights
  Views/
  Resources/  # seed_book.md, Assets, Info.plist
```
