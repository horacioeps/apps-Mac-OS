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
