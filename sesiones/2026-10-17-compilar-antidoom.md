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
