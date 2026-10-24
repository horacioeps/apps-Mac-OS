# Barra Superior

App de macOS (Swift + AppKit/SwiftUI, sin proyecto de Xcode). Pone una barra propia arriba de cada pantalla **mientras la barra de menús de macOS está oculta** (ocultar automáticamente o pantalla completa). Cuando acercas el ratón arriba y baja la barra de menús, esta se desvanece y vuelve cuando la otra se va.

Qué muestra:

- **Izquierda**: los timers activos de *Timers Paralelos PRO* (color, nombre, cuenta atrás). Primero los que corren, el que antes termina delante; luego los pausados (⏸, atenuados) y los que esperan en cola. Rojo en el último minuto.
- **Derecha**: *Tablero IA*: `IA ! permiso ▶ trabajando ⏸ te esperan` y la memoria de Claude Code + Cursor; después la fecha y la hora (la barra de menús oculta se lleva el reloj).

Clic en los timers → abre Timers Paralelos PRO. Clic en la parte IA → abre Tablero IA. Clic derecho → menú (abrir apps, «Abrir al iniciar sesión», salir).

## Instalar / actualizar

```bash
apps/barra/build.sh      # compila, firma ad hoc, instala en /Applications y la abre
```

La primera vez se registra sola como ítem de inicio de sesión (se quita desde el clic derecho).

## De dónde salen los datos

Solo lee dos ficheros que escriben las otras apps:

| Fichero | Lo escribe | Cuándo |
|---|---|---|
| `~/Library/Application Support/Timers Paralelos PRO/active-timers.json` | Timers Paralelos PRO ≥ 28.5.0 | al cambiar un timer (iniciar, pausar, parar, renombrar). Lleva `endTime` absoluto: la cuenta atrás la hace la barra |
| `~/.claude/tablero-ia/barra.json` | Tablero IA ≥ 2.9.0 | cada 5 s |

Los dos llevan el `pid` de la app: si la app se cierra, la barra dice «Timers cerrado» o «Tablero IA cerrado». Tablero también se da por cerrado si el fichero lleva más de 30 s sin cambiar.

## Cómo sabe si la barra de menús está a la vista

El Window Server tiene una ventana «Menubar» por pantalla, en el nivel del menú principal (24). Oculta, está fuera de la pantalla (`y = -30`) y no sale en la lista de ventanas visibles; al bajar vuelve con `y` de -27 a 0. La app consulta `CGWindowListCopyWindowInfo` unas 12 veces por segundo (~1 ms cada vez) y esconde su barra en cuanto asoma la del sistema. Su ventana está un nivel por debajo (23): si la del sistema llega antes que el fundido, la tapa.

## Límites

- La barra tapa los 30 pt de arriba de las ventanas (barras de título, pestañas). macOS no deja reservar ese espacio a otra app.
- En pantallas con notch, el contenido evita la zona de la cámara.
- Si algún día macOS cambia el nombre o el nivel de la ventana «Menubar», la barra se quedaría siempre visible: mirar `menuBars()` en `Sources/main.swift`.
