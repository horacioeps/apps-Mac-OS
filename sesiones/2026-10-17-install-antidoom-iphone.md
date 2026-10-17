# 2026-10-17 — Install AntiDoom on physical iPhone (Horacio M4)

## Pedido

BUILD and INSTALL AntiDoom iOS app onto Horacio's physical iPhone via self-hosted worker `9a40fb81-710e-5c4a-ad7b-6063dbad2b99` (`~/work/Projects/apps-Mac-OS` @ Horacio M4).

## Hecho (bloqueo)

**Install NO ejecutado.** Este subagente corrió en cloud Linux managed, no en el Mac.

### Confirmación de entorno (paso 1)

```
uname -s → Linux
hostname → cursor
pwd → /workspace
runtime (meta-data) → managed
privateWorkerId → null
usePrivateWorker → false
bcId → bc-dfbbafb7-3c6b-5912-a023-09d01d256b31
```

### Worker objetivo

`list-self-hosted-workers` confirma worker online:

- workerId: `9a40fb81-710e-5c4a-ad7b-6063dbad2b99`
- displayName: `~/work/Projects/apps-Mac-OS @ Horacio M4`
- machineDisplayName: Horacio M4
- approved: true
- eligibleForSubagent: true
- sharedAssignmentAllowed: true
- isInUse: false
- OS label: darwin

### Por qué no se instaló

1. Este run no está colocado en el private worker (`privateWorkerId: null`).
2. Como subagente anidado no tiene herramienta `Task` para re-colocarse en el Mac.
3. SSH `EXPLORE_LABS_*` apunta a un Ubuntu Linux (`hostname=ubuntu`), no al Mac; sin `xcodebuild`.
4. No se puede fingir éxito en simulador: no se listó ningún dispositivo ni se lanzó build.

### Acción requerida (parent)

Re-spawn con placement en worker:

- `workerId=9a40fb81-710e-5c4a-ad7b-6063dbad2b99`
- path: `~/work/Projects/apps-Mac-OS`
- mismos pasos: `git pull`, `xcrun xctrace/devicectl list devices`, `xcodebuild` + install/launch en iPhone físico.

## Resultado pedido (este subagente)

| Campo | Valor |
|-------|-------|
| Device name | N/A (este subagente no llegó al Mac) |
| Success/failure | **FAILURE** (placement) |
| Exact error | Agent on managed Linux (`runtime=managed`); target Darwin worker online but not used; no Task tool to re-place |
| App launched | No (por este run) |

## Nota: éxito paralelo en el Mac

Mientras este subagente estaba mal colocado en Linux, otro agent en Horacio M4 (sesión `2026-10-17-compilar-antidoom`) ya completó el objetivo:

- Device: **iPhone Horacio** (iPhone 17 Pro Max), UDID `00008150-00095106149A401C`
- Team: `WMY552P2HR` (Apple Development: Horacio Pérez Sánchez)
- Bundle: `com.horacioeps.antidoom`
- Resultado: **instalada y lanzada** via `xcodebuild` + `devicectl device install app` + `process launch`
