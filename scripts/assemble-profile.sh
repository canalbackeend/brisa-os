#!/usr/bin/env bash
# Monta o perfil archiso final: releng (apenas itens permitidos + menus de boot)
# + modelo em archiso/ + arquivos de branding, com @BRISA_*@ substituídos.
# uso: assemble-profile.sh <releng_dir> <out_dir>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEEP="${RELENG_KEEP:-$ROOT/archiso/releng-keep.txt}"
CONF="${BRISA_CONF:-$ROOT/branding/brisa.conf}"

[[ $# -eq 2 ]] || { echo "uso: $(basename "$0") <releng_dir> <out_dir>" >&2; exit 2; }
RELENG="$1"; OUT="$2"

rm -rf "$OUT"; mkdir -p "$OUT/airootfs"

for d in efiboot syslinux grub; do
  [[ -d "$RELENG/$d" ]] && cp -R "$RELENG/$d" "$OUT/$d"
done

missing=()
while IFS= read -r item; do
  [[ -z "$item" || "$item" == \#* ]] && continue
  if [[ -e "$RELENG/airootfs/$item" || -L "$RELENG/airootfs/$item" ]]; then
    mkdir -p "$OUT/airootfs/$(dirname "$item")"
    cp -RP "$RELENG/airootfs/$item" "$OUT/airootfs/$item"
  else
    missing+=("$item")
  fi
done < "$KEEP"
if (( ${#missing[@]} )); then
  echo "itens do releng não encontrados: ${missing[*]}" >&2
  exit 1
fi

# Modelo próprio (sobrescreve o herdado).
(cd "$ROOT/archiso" && tar --exclude=releng-keep.txt -cf - .) | (cd "$OUT" && tar -xf -)

# Branding.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
BRISA_CONF="$CONF" "$ROOT/scripts/render-branding.sh" "$tmp" >/dev/null
cp "$tmp/os-release" "$OUT/airootfs/etc/os-release"
mkdir -p "$OUT/airootfs/usr/share/pixmaps"
# shellcheck source=/dev/null
source "$CONF"
cp "$ROOT/branding/logo.svg" "$OUT/airootfs/usr/share/pixmaps/$BRISA_ID-logo.svg"
if [[ -d "$tmp/profile" ]]; then (cd "$tmp/profile" && tar -cf - .) | (cd "$OUT" && tar -xf -); fi

ID_UPPER="$(printf '%s' "$BRISA_ID" | tr '[:lower:]' '[:upper:]')"
grep -rlI '@BRISA_' "$OUT" 2>/dev/null | while IFS= read -r f; do
  BN="$BRISA_NAME" BI="$BRISA_ID" BU="$ID_UPPER" BA="$BRISA_ACCENT" perl -pi -e \
    's/\@BRISA_NAME\@/$ENV{BN}/g; s/\@BRISA_ID_UPPER\@/$ENV{BU}/g; s/\@BRISA_ID\@/$ENV{BI}/g; s/\@BRISA_ACCENT\@/$ENV{BA}/g' "$f"
done
echo "perfil montado em $OUT"
