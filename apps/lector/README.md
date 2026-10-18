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

- Destino: **universal** iPhone + iPad (`TARGETED_DEVICE_FAMILY` 1,2), iOS 17+
- Bundle ID: `com.horacioeps.lector` (misma app en ambos)
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
| Preguntador Leitner TEDx (MemorizaGuion) + **LLM** | sí |
| API key embebida local (`Secrets.Local`) + Keychain | sí |
| Highlights + export Markdown | sí |
| Extracción EPUB vía Readium | sí |
| PDF páginas (PDFKit) | sí |
| Fuente Preguntador MemorizaGuion (TEDx local) | integrado (Leitner + cola) |
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
