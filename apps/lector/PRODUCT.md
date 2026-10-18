# Lector (iPad) — product brief

App lectora para iPadOS: zoom multinivel sobre el libro, chat con el contenido, Preguntador (SRS), highlights tipo Readwise propio, y biblioteca amplia (PDF/EPUB + exports Books/Kindle DRM-free + ítems Zotero seleccionados).

## Origen en el vault

Nota del día: `Daily_Notes/2026-10-18.md` (misma idea).

### Zoom a varios niveles (concepto clave)

Nota principal: **«De la visión general al detalle, app para leer libros con zoom inteligente»** (Inbox).

Flujo:

1. Cargar libro (PDF u otro).
2. LLM genera esquema/resumen de alto nivel.
3. El usuario hace clic en un nodo → zoom a resumen más fino (capítulo → sección → subsección…).
4. Al final del árbol: texto **verbatim** del libro.
5. Ayudas en cada nivel: 5 niveles de dificultad (Wired/Feynman), barrido de áreas, preguntas tipo SciSpace, similaridades.

Relacionadas:

- `Zoom progresivo de lectura para ir de un libro a otro sin estancarme`
- `Alternativas a leer de manera normal`
- `Explicando con 5 niveles de dificultad`
- `Ya han implementado mi idea de zooms progresivos…` (referencia LinkedIn TreeReader)
- Prototype previo: chat GPT `Personal / Coding / zoom_libros` (v1 se quedaba pillado)

### Chat

Preguntar al libro (contexto del nodo actual / leído / libro completo). Misma familia que SciSpace / chat in-reader.

### Preguntador (SRS)

Estilo repetición espaciada del proyecto Cursor **«TEDX Almería 2026»** (ensayo de la charla con app de repaso; no encontrado en este VPS — probablemente solo en el Mac).

Referencias vault útiles:

- `App CLI de Estudio. Resumen, Test y Repetición Espaciada` (resumen + test adaptativo + SM-2)
- `Repetición espaciada con cualquier material`
- Notas TEDx: incluir movimientos/entonación «en el repaso con la app»

### Readwise propio

Highlights + export a vault. Ya existe carpeta `Readwise_24` en el vault; la app debe ser la fuente de verdad local (iCloud/SQLite) y poder volcar a Markdown.

### Cualquier contenido

| Fuente | Enfoque realista v1 |
|--------|---------------------|
| PDF / EPUB / TXT / MD | Nativo (Readium + PDFKit) |
| Kindle | Solo AZW3/MOBI **sin DRM** (export usuario); DRM Amazon no |
| Apple Books | Solo libros del usuario exportados / files app-shareables; sin API de biblioteca DRM |
| Zotero seleccionados | Zotero Web API o sync de adjuntos elegidos; ver también plugin Zhutero para outlines |

## Diferenciador

No otra app lineal de ebooks: el **zoom jerárquico resumen→verbatim** + Preguntador + highlights propios. El chat es commodity; el zoom es el producto.

## Plataforma

- Primario: **iPad** (SwiftUI).
- Secundario: iPhone companion / Mac más adelante.
- Motor: ver [SCAFFOLDS.md](SCAFFOLDS.md).

## Estado v0 (código en repo)

Arranque greenfield con Readium SPM + PDFKit:

- `apps/lector/Lector/` — SwiftUI iPad (`com.horacioeps.lector`)
- Zoom extractivo local (headings → párrafos verbatim)
- Chat local anclado al nodo; Preguntador SM-2; highlights + export MD
- Import PDF/EPUB/MD/TXT; semilla `seed_book.md`
- Pendiente: LLM en Zoom/Chat, Navigator EPUB UI, Zotero/Books/Kindle
