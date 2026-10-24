# Barra Superior

App de macOS (Swift + AppKit/SwiftUI, sin proyecto de Xcode). Pone una barra propia arriba de cada pantalla **mientras la barra de menús de macOS está oculta** (ocultar automáticamente o pantalla completa). Cuando acercas el ratón arriba y baja la barra de menús, esta se desvanece y vuelve cuando la otra se va.

Qué muestra:

- **Izquierda**: solo los timers en marcha de *Timers Paralelos PRO* (color, nombre completo, cuenta atrás), el que antes termina delante; el nombre solo se corta si no queda sitio en la barra; los pausados y los que esperan en cola no salen (v1.6.0). Rojo en el último minuto. Si no corre ninguno: «Ningún timer en marcha».
- **Derecha**, bloques separados por `|`: *Tablero IA* (`IA ! permiso ▶ trabajando ⏸ te esperan` y la memoria de Claude Code + Cursor) | RAM del Mac usada / física | fecha y hora (la barra de menús oculta se lleva el reloj). Si falta sitio, quita la fecha, luego la etiqueta «IA» y un decimal, luego las unidades GB y por último la hora.
- Los timers también van separados por `|`.

**Aspecto** (v1.3.0): esquinas redondeadas (12 pt, curva continua, como las ventanas), azul cielo del fondo de escritorio (`#4CB2E2`) con texto blanco en modo claro y oscuro, y un filo fino. Se cambia en `BarBackground`.

**RAM del Mac** (v1.5.0): `usada / física`, sin etiqueta, igual que «Memory Used» y «Physical Memory» del Monitor de Actividad (memoria de apps + fija + comprimida, vía `host_statistics64`). Va justo después de la memoria de Claude + Cursor y antes de la hora.

**Avisos por encima** (v1.7.0): la barra va en el nivel del Dock (20), por encima de todas las ventanas de las apps (0) y de las flotantes (3), pero por debajo de Centro de Notificaciones (21). Los avisos de macOS caen encima de la barra, y la barra llega hasta el borde derecho. La opción de v1.1.0 de dejar libre esa esquina (370 pt) sigue en el clic derecho, apagada por defecto; el ancho se cambia con `defaults write net.horacio.barrasuperior anchoAvisos -int 420`.

**Foto con la webcam** (v1.8.0): el icono de cámara del extremo izquierdo hace una foto sin mostrar nada (ni ventana ni vista previa) y la guarda en `~/Pictures/Barra Superior/AAAA-MM-DD HH.mm.ss.jpg`. Usa la cámara del Mac, no las virtuales (Camo, OBS, Elgato); si no hay (tapa cerrada), la que haya. Espera 1,2 s a que se ajuste la exposición. El icono responde un momento: ✓ guardada, ✕ falló (por ejemplo, sin permiso de cámara). La luz verde de la cámara se enciende ese segundo: es del hardware y no se puede evitar. La primera vez macOS pide permiso de cámara. `build.sh` firma con la identidad «Apple Development» si existe, para que el permiso no se pierda en cada compilación (con firma ad hoc, macOS lo volvería a pedir).

Clic en los timers → abre Timers Paralelos PRO. Clic en la parte IA → abre Tablero IA. Clic derecho → menú (abrir apps, abrir la carpeta de fotos, «Dejar libre la esquina de avisos» —apagada—, «Abrir al iniciar sesión», salir).

## Instalar / actualizar

```bash
apps/barra/build.sh      # compila, firma (Apple Development o ad hoc), instala en /Applications y la abre
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

El Window Server tiene una ventana «Menubar» por pantalla, en el nivel del menú principal (24). Oculta, está fuera de la pantalla (`y = -30`) y no sale en la lista de ventanas visibles; al bajar vuelve con `y` de -27 a 0. La app consulta `CGWindowListCopyWindowInfo` unas 12 veces por segundo (~1 ms cada vez) y esconde su barra en cuanto asoma la del sistema. La barra está por debajo (nivel 20, el del Dock): si la del sistema llega antes que el fundido, la tapa.

## Límites

- La barra tapa los 30 pt de arriba de las ventanas (barras de título, pestañas). macOS no deja reservar ese espacio a otra app.
- En pantallas con notch, el contenido evita la zona de la cámara.
- El contenido acaba 40 pt antes del borde derecho para no pisar el punto naranja (o verde) que macOS pinta arriba a la derecha cuando una app usa el micro o la cámara (`trailingRoom`).
- Si algún día macOS cambia el nombre o el nivel de la ventana «Menubar», la barra se quedaría siempre visible: mirar `menuBars()` en `Sources/main.swift`.
