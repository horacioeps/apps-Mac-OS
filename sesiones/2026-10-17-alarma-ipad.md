# Sesión 2026-10-17 — Alarma iPad

## Usuario

ok quiero para mi ipad, una app simple de despeertador, pero que cuando la activo, salga también en la pantalla bloqueda y que solo tenga dos botnes que sea facil darle, parar y snooze

## Agente

- Creada app **Alarma** en `apps/alarma/` (iPad, iPadOS 26+).
- Usa **AlarmKit**: al sonar muestra alerta de sistema en pantalla bloqueada con **Parar** y **Snooze** (botones grandes del sistema).
- UI simple: ruedas de hora, interruptor Activar (repetición diaria), snooze +/− minutos, botón **Probar en 10 s**.
- Widget extension `AlarmaWidgets` con Live Activity para el countdown de snooze.
- `xcodegen generate` + build simulador: **BUILD SUCCEEDED**.
- README raíz actualizado con la app en la tabla.
- Requiere permiso de Alarmas la primera vez.
