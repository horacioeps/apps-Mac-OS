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

<!-- claude-session bce119cc-8c6d-4a27-a9aa-5208520dbac1 hasta 916cdc04-bd56-4263-b327-90bb186c7c75 -->
