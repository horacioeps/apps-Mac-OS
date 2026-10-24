# Sesión 2026-10-24 — Barra Superior: barra propia cuando la de menús está oculta

## Usuario

como crear para MACOS mi propia barra superior que se veria de manera constsante cuando la otra esta oculta, y que si la otra la invoco, peus desaparece momentameamente, la minina funcinalidad e ninf oseria que piusiera los timers activos de mi proyecto "parallels timers pro" y la memoria total y sesions corriendo y en espera de "IA tablero

## Agente (Claude Code)

Now I'll add the export to Timers Paralelos PRO.

Now the bar itself, as a native Swift app.

Timers tests: 109/109. Now the build script for the bar.

Bar compiles and runs. Now package and relaunch the two Electron apps so they write their files.

Both feeds work. Now checking the bar on screen and the hide/show behaviour.

The bar works but is see‑through (text of the window underneath bleeds in), and on the notch screen macOS pushed it 32 pt down. Fixing both.

Our panel is topmost (level 23), so the bleed comes from its own background: `windowBackgroundColor` isn't fully opaque on macOS 26. Switching to an explicit solid colour.

The bar is opaque. The earlier "bleed" was only the downscaled preview: the Tablero window's title sits just under the 30 pt bar. Now docs, then commits.

Now docs/history in the two other projects, and commit Tablero IA.

Now the session close for apps-mac-os (session dump, HISTORICO, commit + push).

## Agente (Claude Code)

He hecho la barra y ya está funcionando en el Mac: una app nueva, **Barra Superior**, instalada en `/Applications`.

**Cómo se comporta**
- Mientras la barra de menús de macOS está oculta (ocultación automática o pantalla completa), arriba de cada pantalla aparece una franja propia, gris y opaca.
- Al llevar el ratón arriba, la franja empieza a desvanecerse en cuanto asoma la barra de macOS. Cuando esa barra se vuelve a ocultar, la franja reaparece. Lo he comprobado moviendo el ratón con eventos simulados.
- **A la izquierda:** los timers activos de Timers Paralelos PRO, con su color, nombre y cuenta atrás. Primero van los que corren, después los pausados (⏸) y al final los que están en cola. El tiempo se pone en rojo en el último minuto.
- **A la derecha:** los datos de Tablero IA. `IA` y el número de sesiones trabajando (▶, verde) y esperando (⏸, ámbar); si alguna pide permiso, añade `!` en rojo. Después la memoria de Claude Code más Cursor, ahora mismo 9,8 GB. He añadido también la fecha y la hora, porque al ocultar la barra de menús desaparece el reloj.
- **Clics:** sobre los timers abre Timers Paralelos PRO; sobre la parte IA abre Tablero IA. El clic derecho da un menú para abrir las apps, activar o quitar «Abrir al iniciar sesión» y salir. Se registró sola para abrirse al iniciar sesión.

**Cómo está hecha**
- **La barra:** está en [apps/barra/](apps/barra/), es Swift nativo y ocupa muy poca memoria. Se instala con [build.sh](apps/barra/build.sh).
- **Cómo detecta la barra de macOS:** macOS tiene una ventana «Menubar» por pantalla. Cuando está oculta queda fuera de la pantalla y, al bajar, vuelve a aparecer. La app la consulta unas 12 veces por segundo, y cada consulta tarda alrededor de 1 ms.
- **Timers Paralelos PRO (v28.5.0):** ahora escribe sus timers activos en `active-timers.json`, solo cuando cambian. La cuenta atrás la lleva la barra.
- **Tablero IA (v2.9.0):** escribe un `barra.json` cada 5 segundos.
- Si una de las dos apps se cierra, la barra lo indica con «Timers cerrado» o «Tablero IA cerrado».
- **Reinicio:** reinstalé y reabrí las dos apps. No perdiste nada: los dos timers pausados siguen ahí.

**Comprobaciones:** Timers Paralelos PRO pasa sus 109 pruebas. En las capturas, la barra se ve bien en las dos pantallas y en el portátil no tapa el notch.

**Límites**
- La barra tapa los 30 puntos de arriba de las ventanas, donde van las barras de título y las pestañas. macOS no permite que otra app reserve ese espacio.
- Si una versión futura de macOS cambia cómo funciona la ventana «Menubar», la barra se quedaría siempre visible. Está explicado en el [README](apps/barra/README.md).

**Dónde está guardado**
- apps-mac-os y Tablero IA: subidos a `main`. El volcado de la sesión está en `sesiones/2026-10-24-barra-superior.md`.
- Timers Paralelos PRO no tiene git: allí solo actualicé `HISTORICO.md` y `AGENTS.md`.

## Usuario

genial, podemos modificarla para que no "pinte" en la zona derecha donde salen las notificaiones?

## Agente (Claude Code)

The corner is free and the banner shows. Saving and pushing.

## Agente (Claude Code)

Sí. La barra ya no pinta la zona derecha donde salen las notificaciones (v1.1.0, instalada y en marcha). Lo he comprobado con el aviso «Login Item Added» todavía en pantalla: se ve entero, sin la barra encima.

**Qué cambia:**
- **Termina antes:** la barra acaba 380 pt antes del borde derecho, que es lo que ocupa un aviso más su margen. En esa esquina no hay nada nuestro, así que los clics llegan a lo que haya debajo.
- **Recorte de la derecha:** si falta sitio, la parte derecha se recorta: primero quita la fecha y luego la hora. En el portátil ahora se ve `IA ▶1 ⏸11 9,0 GB 11:21`, sin la fecha.
- **Dejarla entera otra vez:** con clic derecho en la barra → **«Dejar libre la esquina de avisos»** la desactivas o la vuelves a activar.
- **Cambiar el ancho:** si algún aviso más ancho aún roza la barra, usa `defaults write net.horacio.barrasuperior anchoAvisos -int 420` y luego reabre la app.

Está en [Sources/main.swift](apps/barra/Sources/main.swift) y explicado en el [README](apps/barra/README.md). Ya está subido a `main`, con el volcado de la sesión y la fila en `HISTORICO.md`.

## Usuario

bien , otra mod, que los bordes no sean 100% cuadrados , si no que sean redondeados, como las ventanas normales del mac. el color que tenga un tono un poco mas oscuro de gris para diferenciarse de las apps nornales

## Agente (Claude Code)

Rounded and darker; it now stands out from the window below. Saving.

<!-- claude-session bce119cc-8c6d-4a27-a9aa-5208520dbac1 hasta a62dd09e-9e7e-4902-89e2-9588125c2936 -->
