# Scaffolds GitHub — investigación 2026-10-18

Objetivo: partir de código existente si acelera, sin copiar licencias incompatibles.

## Recomendación

| Prioridad | Repo | Por qué |
|-----------|------|---------|
| **1. Motor (recomendado)** | [readium/swift-toolkit](https://github.com/readium/swift-toolkit) | BSD-3, EPUB+PDF+audiobooks, SwiftUI navigator, TTS, highlights. Base sólida; UI zoom/chat/SRS propia encima. ~565★ |
| **2. App MIT cercana** | [DaviRain-Su/empty](https://github.com/DaviRain-Su/empty) | SwiftUI macOS+iOS/iPad, EPUB/PDF nativo, AI companion, vocabulario con SRS. MIT. Estudiar / cherry-pick, no clonar todo. |
| **3. Referencia features (no fork)** | [lllyys/vreader](https://github.com/lllyys/vreader) | iPad, EPUB+PDF+AZW3/MOBI, AI chat agentic, annotations. **Sin licencia clara → no fork como base legal.** |
| **4. Workspace AI (Mac)** | [Marvy101/reader-source](https://github.com/Marvy101/reader-source) | MIT, chat contextual, highlights; Mac-first, portable ideas a iPad. |
| **5. Zoom / árbol** | [neurondb/PageIndex](https://github.com/neurondb/PageIndex), [chrisyangqn/zotero-zhutero](https://github.com/chrisyangqn/zotero-zhutero), [earlyadopter/bookatlas](https://github.com/earlyadopter/bookatlas) | Jerarquía TOC/LLM y navegación por zoom; alinear con la nota vault de zoom inteligente. TreeReader (LinkedIn) inspiró la nota «Ya han implementado…». |
| **6. SRS lib** | [4rays/swift-fsrs](https://github.com/4rays/swift-fsrs) / [bootuz/SwiftFSRS](https://github.com/bootuz/SwiftFSRS) | FSRS en Swift para Preguntador (mejor que reinventar SM-2). |
| **7. Lector clásico iOS** | [CHANG-JUI-LIN/Yuedu-reader](https://github.com/CHANG-JUI-LIN/Yuedu-reader) | MPL-2.0, EPUB nativo CoreText; poco AI. Útil solo si se quiere UX tipo Books. |
| **8. Zotero iOS** | [zotero/zotero-ios](https://github.com/zotero/zotero-ios) | Cliente oficial; para «seleccionados» preferir API/adjuntos, no embeber todo Zotero. |

## Encaje con el pedido

| Feature Horacio | Cubierto por scaffold | Hueco (construir) |
|-----------------|----------------------|-------------------|
| Zoom multinivel resumen→verbatim | PageIndex / Zhutero / Bookatlas (idea); nadie iPad completo | UI zoom iPad + generación LLM por nivel |
| Chat | Empty, VReader, Reader | Integrar al nodo de zoom actual |
| Preguntador SRS | Empty (vocab); FSRS libs; CLI vault SM-2 | Flujo tipo TEDx (preguntas sobre *tu* material) |
| Readwise propio | Highlights en Empty/VReader/Readium | Pipeline export → vault Markdown |
| PDF/EPUB | Readium, Empty, Yuedu | — |
| Kindle/Books | VReader AZW3 sin DRM | DRM imposible; UX “importar export” |
| Zotero seleccionados | Zhutero + zotero-ios / Web API | Picker de ítems + sync adjuntos |

## Plan de arranque propuesto

1. **Greenfield** `apps/lector` SwiftUI iPad + dependencia SPM **Readium**.
2. Importar PDF/EPUB locales; v1 sin Kindle/Books DRM.
3. Capa **ZoomTree**: esquema LLM → nodos → enlace a locators Readium/PDFKit.
4. Sheet **Chat** con contexto del nodo.
5. **Preguntador** con FSRS (preguntas generadas del nodo / highlights).
6. Highlights → carpeta vault tipo Readwise.
7. Zotero: import por API de items tagged/`lector`.

No usar VReader como scaffold legal hasta que publiquen licencia. Empty/reader-source sí se pueden estudiar bajo MIT.

## Proyecto TEDx Almería

- Vault: `Inbox/TEDx Almería 2026.md` → Cursor project «TEDX Almería 2026», repaso con app.
- No localizado en VPS Explore-labs ni en repos públicos `horacioeps/*` visibles desde este agent.
- Recuperar del Mac (Finder Personal/Charlas o proyecto Cursor local) cuando haya worker Mac, para reutilizar el Preguntador.
