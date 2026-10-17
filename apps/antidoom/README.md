# AntiDoom

App **iPhone** anti-doomscrolling: te da una **ración finita** de contenido (RSS + tweets semilla). Cuando se acaba, se acabó.

## Abrir en el Mac (Xcode)

```bash
cd apps/antidoom
brew install xcodegen   # si no lo tienes
xcodegen generate
open AntiDoom.xcodeproj
```

Elige un simulador iPhone o tu dispositivo → Run.

## Qué hay

| Pieza | Rol |
|-------|-----|
| [PRODUCT.md](PRODUCT.md) | Definición de producto |
| `AntiDoom/Views/RationView.swift` | Un ítem de la ración (sin scroll infinito) |
| `AntiDoom/Services/RSSClient.swift` | RSS/Atom mínimo |
| `AntiDoom/Resources/seed_tweets.json` | Tweets de ejemplo (edítalos) |
| `project.yml` | Genera el `.xcodeproj` con XcodeGen |

## v1

- Feeds RSS (blogs, noticias, podcasts) configurables en Ajustes.
- Tweets desde JSON local.
- Tamaño de ración (3–15).

## v1.1 (pendiente)

Vault de notas, grabadora continua, bookmarks, tweets en vivo.
