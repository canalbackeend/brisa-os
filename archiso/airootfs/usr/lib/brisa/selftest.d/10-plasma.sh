#!/usr/bin/env bash
# Autoteste: Plasma rodando em Wayland para o usuário live, Baloo desligado, RAM ociosa.
set -u
PROC="${BRISA_PROC:-/proc}"
WAIT="${BRISA_WAIT:-300}"
RAM_DELAY="${BRISA_RAM_DELAY:-120}"
HOME_LIVE="${BRISA_LIVE_HOME:-/home/live}"

plasma_env() {
  local d
  for d in "$PROC"/[0-9]*; do
    [[ "$(cat "$d/comm" 2>/dev/null)" == plasmashell ]] || continue
    tr '\0' '\n' < "$d/environ" 2>/dev/null | grep '^XDG_SESSION_TYPE=' || echo "XDG_SESSION_TYPE=?"
    return 0
  done
  return 1
}

state=""
for (( i = 0; i < WAIT; i += 5 )); do
  if state="$(plasma_env)"; then break; fi
  (( WAIT > 1 )) && sleep 5
done
if [[ "$state" == "XDG_SESSION_TYPE=wayland" ]]; then echo "BRISA:plasma=ok"; else echo "BRISA:plasma=falhou"; fi

if grep -qx 'Indexing-Enabled=false' "$HOME_LIVE/.config/baloofilerc" 2>/dev/null; then
  echo "BRISA:baloo=off"
else
  echo "BRISA:baloo=on"
fi

if (( RAM_DELAY > 0 )) && command -v free >/dev/null; then
  sleep "$RAM_DELAY"
  echo "BRISA:ram_mb=$(free -m | awk '/^Mem:/ {print $3}')"
fi
