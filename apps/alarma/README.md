# Alarma

Despertador simple para **iPad** (iPadOS 26+). Usa **AlarmKit**: al sonar aparece en la **pantalla bloqueada** con dos botones grandes del sistema — **Parar** y **Snooze**.

## Requisitos

- iPadOS **26.0** o superior (AlarmKit)
- Xcode 26+
- Autorización de Alarmas la primera vez (o en Ajustes → Alarma)

## Abrir / instalar

```bash
cd apps/alarma
xcodegen generate
open Alarma.xcodeproj
```

En Xcode: elige tu **iPad** (o simulador iPad), Team `WMY552P2HR`, Run ▶.

## Uso

1. Elige la hora con las ruedas.
2. Activa el interruptor (repite cada día a esa hora).
3. Ajusta minutos de snooze (+ / −).
4. **Probar en 10 s**: bloquea el iPad; verás Parar y Snooze en la pantalla bloqueada.

Sonido: **arpa** original sintetizado (`Alarma/Resources/arpa.caf`).

## App Store

Borrador en [`store/`](store/): metadata, `privacy.html`, `upload.sh`, archive Release ya generado en `build/Archive.xcarchive`.

Bloqueos actuales al exportar:

1. Aceptar el **Program License Agreement** (PLA) en [developer.apple.com/account](https://developer.apple.com/account).
2. Crear la app en App Store Connect (`com.horacioeps.alarma`) y publicar URL de privacidad.
3. Volver a ejecutar `store/upload.sh` (renueva certificado Distribution caducado y sube el build).

## Piezas

| Pieza | Rol |
|-------|-----|
| `Alarma/Services/AlarmStore.swift` | AlarmKit: auth, schedule, snooze |
| `Alarma/Views/AlarmHomeView.swift` | UI grande para iPad |
| `AlarmaWidgets/` | Live Activity del countdown de snooze |
| `Shared/WakeAlarmMetadata.swift` | Metadata compartida app ↔ widget |
