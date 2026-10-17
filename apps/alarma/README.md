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

Sonido: **arpa** (`Alarma/Resources/arpa.caf`, tono Harp del sistema convertido a CAF).

## Piezas

| Pieza | Rol |
|-------|-----|
| `Alarma/Services/AlarmStore.swift` | AlarmKit: auth, schedule, snooze |
| `Alarma/Views/AlarmHomeView.swift` | UI grande para iPad |
| `AlarmaWidgets/` | Live Activity del countdown de snooze |
| `Shared/WakeAlarmMetadata.swift` | Metadata compartida app ↔ widget |
