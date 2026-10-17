# AntiDoom

App **iPhone** anti-doomscrolling: una **ración finita** de contenido (RSS + tweets). Cuando se acaba, se acabó.

## Instalar / abrir en el Mac

Hace falta **Xcode** (Mac). Desde este cloud no se puede instalar en el iPhone.

```bash
cd ~/work/Projects/apps-Mac-OS   # o donde tengas el clone
git pull origin main
open apps/antidoom/AntiDoom.xcodeproj
```

En Xcode:

1. Elige un **simulador iPhone** (o tu iPhone con Developer Mode).
2. Si pide Team: pon tu Apple ID en Signing & Capabilities.
3. Pulsa **Run** (▶).

## Qué hay

| Pieza | Rol |
|-------|-----|
| [PRODUCT.md](PRODUCT.md) | Producto |
| `AntiDoom/Views/RationView.swift` | Un ítem de la ración |
| `AntiDoom/Services/RSSClient.swift` | RSS/Atom |
| `AntiDoom/Resources/seed_tweets.json` | Tweets de ejemplo |
| `AntiDoom.xcodeproj` | Proyecto Xcode listo |

## Fuentes (defaults)

- Emilcar Daily (podcast RSS)
- Hacker News (noticias; la app genera un **Resumen:** extractivo)
- Swift.org Blog
- Tweets: `AntiDoom/Resources/seed_tweets.json`
- Vault: `AntiDoom/Resources/seed_notes.json` (trozos de Daily Notes)

```bash
python3 apps/antidoom/scripts/sync_vault_notes.py   # regenera seed_notes desde ~/Library/Obsidian/Horacio
```

## v1 / v1.1

- **v1:** RSS + tweets JSON, tamaño de ración en Ajustes.
- **v1.1:** resumen de noticias + vault (semilla Daily Notes). Grabadora / bookmarks / tweets API → después.
