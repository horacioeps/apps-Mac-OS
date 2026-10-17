# Sesión: recover AntiDoom from Mac / temp Cursor repo

## Pedido (subagent «Recover antidoom from Mac»)

CRITICAL: run on Horacio M4 if possible. WorkerIds:
- `915e4d6d-af12-5009-b981-8bcba143f7ab`
- `9a40fb81-710e-5c4a-ad7b-6063dbad2b99`

Recover AntiDoom from Cursor Cloud session «Mac OS cloud apps» (`bc-285f4153…`) temp repo:
`origin.cursor.com/git/horacio-ps/tmp-0fb6de09ea4f32da`

Expected: `apps/antidoom/PRODUCT.md`, SwiftUI skeleton with `RationView`, `sesiones/2026-10-17-apps-macos-inicio.md`.

Search Mac: `~/Library/Application Support/Cursor/`, `~/.cursor/`, caches of tmp repo, transcripts, `~/work/Projects/`.

## Resultado

### Host de este agent

- **No es el Mac.** VM cloud Linux.
- `hostname=cursor`
- `uname=Linux cursor 6.12.94+ #1 SMP PREEMPT_DYNAMIC Fri Oct 16 00:53:04 UTC 2026 x86_64`
- Meta-data: `runtime=managed`, repo `github.com/horacioeps/apps-Mac-OS`
- Run: `bc-c0b06a3b-0fda-51dc-9412-4c21589d91e4` («Recover antidoom from Mac»), `privateWorkerId=null`, `usePrivateWorker=false`

### Workers Horacio M4 (conectados, eligibleForSubagent=true)

| workerId | displayName |
|----------|-------------|
| `9a40fb81-710e-5c4a-ad7b-6063dbad2b99` | ~/work/Projects/apps-Mac-OS @ Horacio M4 |
| `915e4d6d-af12-5009-b981-8bcba143f7ab` | ~/work/Projects/.../Synergium @ Horacio M4 |
| `8f9e8395-1f57-517f-8747-3730126de36d` | Emailer X local @ Horacio M4 |

Este subagent **no** fue colocado en ninguno (no tiene herramienta Task/CreateAgent con `workerId`).

### bc-285f4153…

- Prefijo conocido; **ID completo no encontrado** en vault, VPS, transcripts accesibles, ni list-cloud-agents (otro environment).
- `batch-fetch-details` con `bc-285f4153` → not found / not accessible.
- Captura en assets confirma sesión «Mac OS cloud apps», tmp repo, PRODUCT.md + RationView, pero sin UUID completo.

### Temp git repo

URLs probadas:
- `https://origin.cursor.com/git/horacio-ps/tmp-0fb6de09ea4f32da` → existe; pide auth Cursor (`origin auth login`); GitHub PAT rechazado.
- `https://cursor.com/git/horacio-ps/tmp-0fb6de09ea4f32da` → no es git repo válido vía HTTPS anónimo.

**Nunca en GitHub.** Sin clone URL usable desde este agent.

### Archivos buscados — no hallados

- `apps/antidoom/PRODUCT.md` — no
- SwiftUI / `RationView` — no
- `sesiones/2026-10-17-apps-macos-inicio.md` — no
- Cache `tmp-0fb6de09ea4f32da` en Mac — inaccesible desde aquí
- Paths Mac (`~/Library/...`, `~/work/Projects/`) — no existen en esta VM

### Lo único recuperable (ya en repo / vault)

- Vault `Daily_Notes/2026-10-16.md`: nota anti-doomscrolling + `==creada en cursor cloud==`
- `apps/antidoom/README.md` (spec parcial, sin PRODUCT.md ni SwiftUI)

## Siguiente paso útil

Relanzar agent **self-hosted** en worker `9a40fb81-710e-5c4a-ad7b-6063dbad2b99` (apps-Mac-OS @ Horacio M4) o pegar URL completa `https://cursor.com/agents/bc-285f4153-…` / hacer `origin auth login` y clonar el tmp repo.
