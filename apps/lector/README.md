# Lectura

App **Lectura** (bundle `com.horacioeps.lector`): zoom multinivel + chat + Preguntador (SRS) + highlights. Motor **Readium** (SPM) + PDFKit.

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

1. Abre Lectura → ⚙ Ajustes  
2. API key embebida local o pégala → modelo (default `gpt-4o-mini`) → Guardar  
3. Al abrir un libro, el zoom pide resúmenes LLM; el chat y «Generar con LLM» del Preguntador la usan.

### Depuración (trazas + pantallas)

Cuando algo falle en el iPhone/iPad:

1. En la app: botón **🐞 Volcar** (o agitar el dispositivo). También se vuelca solo al abrir un libro.
2. En el Mac, desde esta carpeta:

```bash
./scripts/pull-dumps.sh          # sim o device
./scripts/pull-dumps.sh device   # forzar iPhone/iPad
./scripts/pull-dumps.sh sim      # forzar simulador
```

3. Los ficheros quedan en `debug-dumps/` (`state.json`, `trace.jsonl`, `screen.png`). Dile al agente «mira el dump» o describe el error: con el volcado se ve la pantalla y el rastro.

Páginas renderiza Markdown (títulos tipográficos, sin `#` crudos).

## Estructura

```
Lector/
  LectorApp.swift
  Models/
  Services/   # Library, ZoomTree, ReadiumBridge, Chat, Preguntador, Highlights
  Views/
  Resources/  # seed_book.md, Assets, Info.plist
```
