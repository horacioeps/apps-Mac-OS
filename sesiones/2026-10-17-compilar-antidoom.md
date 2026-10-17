# Sesión: Compilar AntiDoom

## Usuario

compila

## Agente

- Proyecto: `apps/antidoom/AntiDoom.xcodeproj` (scheme AntiDoom).
- `xcode-select` apuntaba a Command Line Tools; sin sudo no se pudo cambiar. Se usó `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- Build Debug para `generic/platform=iOS Simulator` con `-derivedDataPath build`.
- Resultado: **BUILD SUCCEEDED** (~17 s).
- App: `apps/antidoom/build/Build/Products/Debug-iphonesimulator/AntiDoom.app`
- Añadido `build/` a `apps/antidoom/.gitignore` (artefactos locales, no al repo).

## Usuario

no las puedes enviar directamente al iphone ?

## Agente

- Sí, cuando el iPhone está emparejado y hay firma de desarrollo.
- Dispositivo: iPhone Horacio (iPhone 17 Pro Max, UDID `00008150-00095106149A401C`) — available (paired).
- Team: `WMY552P2HR` (Apple Development: Horacio Pérez Sánchez).
- Build Debug para dispositivo físico + `devicectl device install app` + `process launch`.
- Resultado: instalada y lanzada `com.horacioeps.antidoom` en el iPhone.

## Usuario

funciona. pero, de las noticias, quiero que antes las proceses y me metas un trozo tipo resumen. y tambien, metes trozos relevanes de mi vault? cuales son las fuentes ?

## Agente

Fuentes actuales (defaults):
- Emilcar Daily (podcast RSS)
- Hacker News (noticias)
- Swift.org Blog
- Tweets: `seed_tweets.json`
- Vault: `seed_notes.json` desde Daily Notes

Hecho:
- `SummaryProcessor`: noticias con prefijo `Resumen:` (extractivo on-device).
- `VaultNoteLoader` + `scripts/sync_vault_notes.py` (trozos de `~/Library/Obsidian/Horacio/Daily_Notes`).
- Ración mezcla hasta 2 notas de vault.
- Reinstalada en iPhone 17 Pro Max.
- Aclarado: resumen aún no es LLM; vault aún no lee Obsidian en vivo en el teléfono (semilla al desplegar desde Mac).
