# Sesión 2026-10-18 — Lector iPad / scaffolds

## Pedido (usuario)

```
Esta idea de app pero antes mira si hay apps similares en GitHub de las que podamos partir como scaffold , App lector de libros para iPad con 
- Zoom a varios niveles 
	- Buscar el concepto en mi vault 
- Chat 
	- Para preguntarle 
- pREGUNtADoR 
	- Tipo repetición espaciada como el proyecto de tedxalmeria 
- mi propio Readwise 
- Que pueda leer cualquier contenido 
	- No solo PDF y EPUB etc si no tambien 
		- Libros de las apps books y kindle y zoTERO SELECCIONADOS 
```

(Coincide con `Daily_Notes/2026-10-18.md` del vault.)

## Hecho

### Vault (VPS sync)

Concepto zoom encontrado:

- `Inbox/De la visión general al detalle, app para leer libros con zoom inteligente.md` — esquema LLM → zoom clic → verbatim; 5 niveles; SciSpace-like.
- Relacionadas: Zoom progresivo…, Alternativas a leer…, Explicando con 5 niveles…, Ya han implementado… (TreeReader LinkedIn), prototype `zoom_libros`.
- TEDx: `Inbox/TEDx Almería 2026.md` — proyecto Cursor «TEDX Almería 2026», «repaso con la app». No hallado el código en VPS.
- SRS: `App CLI de Estudio. Resumen, Test y Repetición Espaciada` (SM-2).
- Vault ya tiene `Readwise_24/` y `Zotero/`.

### GitHub scaffolds

Documentado en `apps/lector/SCAFFOLDS.md`:

- Recomendado: **Readium swift-toolkit** (BSD-3) como motor + UI propia.
- MIT cercanos: **empty**, **reader-source**.
- VReader (features Kindle/AI) pero **sin licencia** → no fork.
- Zoom tree: PageIndex, Zhutero, Bookatlas.
- FSRS Swift para Preguntador.

### Repo

- `apps/lector/PRODUCT.md` + `SCAFFOLDS.md`
- README tabla actualizada
- Push `main`

## Pendiente / siguiente

- Decidir: greenfield Readium vs estudiar Empty.
- Recuperar proyecto Cursor TEDx del Mac para Preguntador.
- No implementar código Swift aún (solo research + spec, como pedía el usuario).

---

## Follow-up: Arranca con lo recomendado

### Pedido

```
Arranca con lo recomendado
```

### Hecho

Greenfield `apps/lector` SwiftUI iPad:

- SPM Readium 3.11.1 (`ReadiumShared` + `ReadiumStreamer`)
- PDFKit para PDF; extracción EPUB vía ReadiumBridge
- ZoomTreeService extractivo, ChatService local, PreguntadorStore SM-2, HighlightStore + export MD
- Biblioteca + import + seed_book.md
- `project.yml`, `Lector.xcodeproj`, README
- Push `main`

### Pendiente

- Compilar en Mac/Xcode (este agent es Linux)
- LLM en zoom/chat; EPUBNavigator UI; Zotero/Books/Kindle

---

## Follow-up: ambas (LLM + TEDx)

### Pedido

```
ambas
```

(= conectar LLM al zoom/chat **y** recuperar Preguntador TEDx del Mac)

### Hecho

**LLM**
- `LLMClient` + `LLMSettings` (Keychain) + `SettingsView`
- Zoom: `enrichWithLLM` tras árbol extractivo
- Chat: OpenAI con historial + fallback local
- Preguntador: `seedWithLLM` (JSON cards, detailLevel, hints) + prioridad due/lapses

**TEDx Mac**
- Workers M4 online (`9a40fb81…` apps-Mac-OS) pero Task/subagents solo corren en Linux cloud (`privateWorkerId=null`, sin API de placement).
- Vault: App CLI estudio = diseño SM-2 (todo), no código; TEDx note apunta a Cursor «TEDX Almería 2026» en Personal/Charlas.
- Preguntador Lector portó el comportamiento descrito (escaletas/pistas/SM-2/LLM) sin el repo Mac.

### Pendiente usuario/Mac

- Relanzar agent **self-hosted** en worker `~/work/Projects/apps-Mac-OS @ Horacio M4` y buscar `TEDXAlmeria` / Personal/Charlas para fusionar código original si existe.
- Compilar Lector en Xcode; pegar API key en Ajustes.

---

## Follow-up: guarda sesion (2026-10-18 08:09 UTC)

### Pedido

```
guarda sesion
```

### Hecho

- Comprobado: carpeta `sesiones/` existe; volcado `sesiones/2026-10-18-lector-ipad-scaffolds.md` ampliado con este turno.
- `HISTORICO.md` actualizado (fila «guarda sesion»).
- README ya enlaza HISTORICO.
- Sync: `git pull --rebase origin main` → commit → `git push origin main`.

### Resumen compacto de la conversación completa

1. Idea app Lector iPad (zoom/chat/Preguntador/Readwise/fuentes) → búsqueda vault + scaffolds GitHub → Readium recomendado.
2. «Arranca con lo recomendado» → greenfield `apps/lector` SwiftUI + Readium/PDFKit.
3. «ambas» → LLM OpenAI (Zoom/Chat/Preguntador) + intento recuperar TEDx Mac (bloqueado sin placement worker); SRS estilo vault portado.
4. «guarda sesion» → este volcado + HISTORICO + push.

---

## Follow-up: lee esta sesion y dime que queda por hacer (2026-10-18 08:10 UTC)

### Pedido

```
lee esta sesion y dime que queda por hacer
```
(Captura: «Sesión guardada…» con enlace a este volcado.)

### Hecho

- `git pull --rebase origin main` (faltaba el commit del scaffold Lector en la copia local).
- Leído el volcado completo + `PRODUCT.md` / `SCAFFOLDS.md` / `README.md` de `apps/lector`.
- Respuesta al usuario: lista de pendientes (Mac/Xcode, API key, TEDx worker, Navigator EPUB, Zotero/Books/Kindle, FSRS opcional).



---

## Follow-up: compila + API key + Preguntador TEDx local (2026-10-18 08:16 UTC)

### Pedido

```
compila y meet la api open ai key dentro de la app, nunca voy a comartir esta app. y el preguntador lo puedes enoncrar ahora en el proyecto local en este mac
```

### Hecho

- Hallado Preguntador TEDx: `Personal/Charlas/TEDX Almería 2026/app/repeticion espaciada iOS` (MemorizaGuion).
- Preguntador Lector: cajas Leitner + cola sesión (Nucleo/Cola) + UI Ver / Pista / Reintentar / OK.
- OpenAI: `API_KEY_OPEN_AI` → `Lector/Secrets.Local.swift` (**gitignored**); seed a Keychain al arrancar. No va al repo.
- Build OK (Xcode 26.6) + install + launch en iPad de Horacio (`com.horacioeps.lector`).
- Fix actor: `LibraryStore.booksDirectory` nonisolated.



---

## Follow-up: notificación shell abortado (2026-10-18 08:16 UTC)

### Pedido
Sistema: informar del task shell abortado (Find API key / TEDx / devices).

### Hecho
- Ese shell se abortó por timeout; no hace falta reejecutarlo.
- Resultados ya usados en el turno anterior (TEDx MemorizaGuion, API key, devices iPad).



---

## Follow-up: universal iPhone + iPad (2026-10-18 08:17 UTC)

### Pedido

```
podemos tener dos versiones, una ipad y otra de mi iphone xs max pro 17 ?
```

### Hecho

- Una sola app universal (`TARGETED_DEVICE_FAMILY` 1,2) — no dos bundle IDs.
- Orientaciones iPhone en Info.plist.
- BUILD SUCCEEDED; install+launch en **iPad** y **iPhone 17 Pro Max**.
- iPhone XS Max aparece en CoreDevice como *unavailable* (no emparejado/túnel); mismo binario sirve cuando esté online.



---

## Follow-up: Capas + icono + TraceDump (2026-10-18 10:33 UTC)

### Pedido

```
la app de lector la acabo de ver en el iphoe. lo primero si le podemos poner un nombre mas diferenciador pero simple. luego ponerle un icono original. luego he añadido un libro, me he puesto a leerlo pero lo que sale es un desastre. par que lo entiendas, añade un mecanismo de volcado de trazas y pantallas de manera qe teu enel simulador puedas ver lo que esta pasando cada vez que te informo de un error, ok ?
```

### Hecho

- Nombre en dispositivo: **Capas** (bundle sigue `com.horacioeps.lector`).
- Icono original (capas/zoom) en AppIcon.appiconset.
- `TraceDump`: trazas + state.json + screen.png en Documents/CapasDumps; botón 🐞 / shake / auto al abrir libro; `scripts/pull-dumps.sh` → `debug-dumps/` (gitignored).
- ZoomTreeView envuelto en ScrollView (mitiga desborde).
- Install iPad + iPhone 17 Pro Max.

### Flujo para errores

Usuario reproduce → Volcar (o auto) → «mira el dump» → agente `./scripts/pull-dumps.sh` y lee latest/.



---

## Follow-up: mira las trazas (2026-10-18 10:38 UTC)

### Pedido
```
mira las trazas porq ue sale mal todavia
```

### Diagnóstico (dump iPhone `20261018-123351`)
- Libro: EPUB *Maybe You Should Talk to Someone* (400k chars).
- Zoom: **87 hijos «§ N»** — blob plano sin TOC; `leafChunks` por párrafo.
- `zoomMode=extractivo`; resumen raíz 1644 chars (TOC basura).
- `screen.png` = spinner (dump antes de `loading=false`).

### Fix
- Readium: `extractChapters` por spine + títulos TOC/NCX.
- ZoomTree: un nodo por capítulo, chunks fusionados (máx ~10), resumen corto; filtra boilerplate.
- Dump tras pintar UI (+250ms).
- Reinstall iPhone + iPad. Pedir reabrir libro y nuevo dump si sigue mal.

