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
