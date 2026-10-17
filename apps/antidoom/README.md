# AntiDoom

Primera app del ecosistema Apple de Horacio (concepto recuperado 2026-10-17).

## Qué es

App para **iPhone** contra el doomscrolling: cuando te atrapa el scroll infinito, te ofrece algo mejor sacado de **tu propio conocimiento** (notas) y de **podcasts elegidos**, en lugar de más feed.

## Fuentes (MVP)

1. **Notas del vault Markdown personal** (app de notas enlazadas; nombre: ver abajo) — busca en el vault del usuario. <!-- pragma: allowlist secret -->
2. **Podcasts** — al menos [Emilcar Daily](https://emilcar.fm/) (y otros que se acuerden después).

Nombre de la app de notas: Obsidian <!-- pragma: allowlist secret -->

## Idea de uso

- Detectar / interrumpir el hábito de scroll (o lanzarse a mano cuando quieres salir del scroll).
- Recuperar un fragmento útil: nota del vault o episodio / idea de podcast.
- Sustituir “más feed” por “algo mío / algo que ya elegí escuchar”.

## Plataforma

- Objetivo: **iPhone** (iOS).
- Vive en este repo (`apps-Mac-OS`) como primer proyecto Apple documentado; el scaffold nativo (SwiftUI / Xcode) se añadirá en siguientes sesiones.

## Estado

- Spec mínima escrita; **sin código de app aún**.
- Pendiente: UX concreta (interrupción vs launcher), indexado del vault, integración con podcasts, nombre de bundle / permisos.
