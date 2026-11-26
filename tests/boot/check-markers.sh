#!/usr/bin/env bash
# uso: check-markers.sh <log_serial> chave=valor... → 0 se todas as linhas BRISA:chave=valor aparecem.
set -euo pipefail
[[ $# -ge 2 ]] || { echo "uso: $(basename "$0") <log> chave=valor..." >&2; exit 2; }
log="$1"; shift
missing=()
for kv in "$@"; do
  tr -d '\r' < "$log" | grep -qxF "BRISA:$kv" || missing+=("$kv")
done
if (( ${#missing[@]} )); then
  echo "marcadores ausentes: ${missing[*]}"
  exit 1
fi
echo "todos os marcadores presentes: $*"
