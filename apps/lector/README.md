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

## v0 incluido

| Pieza | Estado |
|-------|--------|
| Biblioteca + import PDF/EPUB/MD/TXT | sí |
| Libro semilla `seed_book.md` | sí |
| Zoom árbol extractivo (headings → verbatim) | sí |
| Chat anclado al nodo (local, sin LLM aún) | sí |
| Preguntador SM-2 desde nodos zoom | sí |
| Highlights + export Markdown | sí |
| Extracción EPUB vía Readium | sí |
| PDF páginas (PDFKit) | sí |
| LLM para resúmenes de zoom | pendiente |
| Zotero / Books / Kindle DRM | pendiente (import manual sin DRM) |
| EPUBNavigator UI nativa Readium | pendiente |

## Estructura

```
Lector/
  LectorApp.swift
  Models/
  Services/   # Library, ZoomTree, ReadiumBridge, Chat, Preguntador, Highlights
  Views/
  Resources/  # seed_book.md, Assets, Info.plist
```
