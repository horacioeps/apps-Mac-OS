# AntiDoom — producto

## Problema

El scroll infinito (redes, feeds) te atrapa. Quieres algo finito, elegido por ti, no un pozo sin fondo.

## Promesa

Una **ración** al día (o bajo demanda): un número pequeño de piezas de contenido tuyo / que ya elegiste seguir. Cuando se acaba, se acabó. No hay “más abajo”.

## Fuentes

| Fuente | v1 | v1.1+ |
|--------|----|-------|
| RSS blogs | sí | |
| RSS / feed noticias | sí | |
| Podcasts (RSS) | sí | |
| Tweets (lista / bookmarks vía API o export) | sí (lista estática o JSON local) | API en vivo |
| Vault de notas Markdown | | sí |
| Grabadora continua | | sí |
| Bookmarks genéricos | | sí |

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
