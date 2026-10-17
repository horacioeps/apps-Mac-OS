# AntiDoom — producto

## Problema

El scroll infinito (redes, feeds) te atrapa. Quieres algo finito, elegido por ti, no un pozo sin fondo.

## Promesa

Una **ración** al día (o bajo demanda): un número pequeño de piezas de contenido tuyo / que ya elegiste seguir. Cuando se acaba, se acabó. No hay “más abajo”.

## Fuentes

| Fuente | Ahora | Default |
|--------|-------|---------|
| Podcasts (RSS) | sí | Emilcar Daily (`feeds.feedburner.com/emilcar`) |
| RSS / feed noticias | sí + resumen extractivo | Hacker News (`hnrss.org/frontpage`) |
| RSS blogs | sí | Swift.org Blog (`swift.org/atom.xml`) |
| Tweets | sí (JSON local) | `Resources/seed_tweets.json` |
| Vault de notas Markdown | sí (semilla desde Daily Notes) | `Resources/seed_notes.json` vía `scripts/sync_vault_notes.py` |
| Grabadora continua | | v1.2 |
| Bookmarks / tweets API | | v1.2 |

Los feeds se pueden activar/desactivar en Ajustes. Si ya guardaste feeds en el teléfono, hay que recargar o borrar datos de la app para ver defaults nuevos.

## UX central: RationView

- Pantalla principal = la ración de hoy.
- Cada ítem: título, fuente, extracto corto, abrir enlace / reproducir.
- Contador visible: `3 de 7`.
- Al terminar la ración: pantalla de cierre (sin feed infinito).
- Ajustes: tamaño de ración, feeds RSS, lista de tweets.

## Fuera de alcance v1

- Overlay sobre Instagram/TikTok/X.
- Indexado completo del vault.
- Sync iCloud del vault.
- Detección automática de doomscrolling en segundo plano.
