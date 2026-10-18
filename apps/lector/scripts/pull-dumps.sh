#!/usr/bin/env bash
# Trae CapasDumps del dispositivo o simulador a apps/lector/debug-dumps/
set -euo pipefail
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/debug-dumps"
mkdir -p "$OUT"
BUNDLE="com.horacioeps.lector"

pull_sim() {
  local udid="${1:-}"
  if [[ -z "$udid" ]]; then
    udid="$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((x["udid"] for runtime in d.get("devices",{}).values() for x in runtime if x.get("state")=="Booted"), ""))')"
  fi
  [[ -n "$udid" ]] || { echo "No hay simulador booted"; return 1; }
  local container
  container="$(xcrun simctl get_app_container "$udid" "$BUNDLE" data 2>/dev/null || true)"
  [[ -n "$container" ]] || { echo "App no instalada en sim $udid"; return 1; }
  local src="$container/Documents/CapasDumps"
  [[ -d "$src" ]] || { echo "Sin CapasDumps en sim: $src"; return 1; }
  rsync -a --delete "$src/" "$OUT/sim/"
  echo "OK sim → $OUT/sim/"
  ls -la "$OUT/sim/latest" 2>/dev/null || ls -la "$OUT/sim" | tail -5
}

pull_device() {
  local device="${1:-}"
  if [[ -z "$device" ]]; then
    device="$(xcrun devicectl list devices 2>/dev/null | awk '/available \(paired\)/ {print $3; exit}')"
  fi
  [[ -n "$device" ]] || { echo "No hay device paired"; return 1; }
  local tmp
  tmp="$(mktemp -d)"
  # Copia contenedor de documentos de la app
  if xcrun devicectl device copy from --device "$device" --domain-type appDataContainer --domain-identifier "$BUNDLE" --source Documents/CapasDumps --destination "$tmp/CapasDumps" 2>/dev/null; then
    rsync -a --delete "$tmp/CapasDumps/" "$OUT/device/"
    echo "OK device ($device) → $OUT/device/"
    ls -la "$OUT/device/latest" 2>/dev/null || ls -la "$OUT/device" | tail -5
  else
    echo "devicectl copy falló. Alternativa: Archivos › Capas › CapasDumps › AirDrop/carpeta compartida."
    echo "Intentando listar..."
    xcrun devicectl device info files --device "$device" --domain-type appDataContainer --domain-identifier "$BUNDLE" 2>&1 | head -40 || true
    return 1
  fi
  rm -rf "$tmp"
}

case "${1:-auto}" in
  sim) pull_sim "${2:-}" ;;
  device) pull_device "${2:-}" ;;
  auto)
    if pull_sim 2>/dev/null; then exit 0; fi
    pull_device
    ;;
  *) echo "Uso: $0 [auto|sim|device] [udid]"; exit 2 ;;
esac
