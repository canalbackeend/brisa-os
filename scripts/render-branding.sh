#!/usr/bin/env bash
# Gera os arquivos derivados da identidade da distro a partir de branding/brisa.conf.
# uso: render-branding.sh <out_dir>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="${BRISA_CONF:-$ROOT/branding/brisa.conf}"

if [[ $# -ne 1 ]]; then
  echo "uso: $(basename "$0") <out_dir>" >&2
  exit 2
fi
OUT="$1"

# shellcheck source=/dev/null
source "$CONF"
: "${BRISA_NAME:?BRISA_NAME ausente}" "${BRISA_ID:?BRISA_ID ausente}"

mkdir -p "$OUT"

cat > "$OUT/os-release" <<EOR
NAME="$BRISA_NAME"
PRETTY_NAME="$BRISA_NAME"
ID=$BRISA_ID
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;91;140;255"
HOME_URL="$BRISA_URL"
LOGO=$BRISA_ID-logo
EOR

printf '%s\n' "$BRISA_NAME" > "$OUT/brisa-name.txt"
