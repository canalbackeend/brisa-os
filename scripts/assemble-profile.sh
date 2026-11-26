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

# Menus de boot herdados do releng: nome da distro no lugar de "Arch Linux".
for d in efiboot syslinux grub; do
  [[ -d "$OUT/$d" ]] || continue
  { grep -rlI "Arch Linux" "$OUT/$d" 2>/dev/null || true; } | while IFS= read -r f; do
    perl -pi -e 's/Arch Linux install medium/\@BRISA_NAME\@ Live/g; s/Arch Linux/\@BRISA_NAME\@/g' "$f"
  done
done
rm -f "$OUT/syslinux/splash.png"
if command -v rsvg-convert >/dev/null && [[ -d "$OUT/syslinux" ]]; then
  rsvg-convert -w 640 -h 480 --keep-aspect-ratio "$ROOT/branding/wallpaper.svg" -o "$OUT/syslinux/splash.png"
fi

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
# Modos de interface: padrões do sistema = modo macOS; arquivos completos para troca.
A="$OUT/airootfs"
mkdir -p "$A/usr/share/brisa" "$A/usr/share/plasma/look-and-feel" "$A/usr/bin" "$A/etc/xdg" "$A/etc/skel"
cp -R "$ROOT/modes" "$A/usr/share/brisa/modes"
cp -R "$ROOT/modes/macos/look-and-feel/org.brisa.macos" "$A/usr/share/plasma/look-and-feel/"
cp "$ROOT/scripts/brisa-aplicar-modo" "$A/usr/bin/"
cp "$ROOT"/modes/macos/config/xdg/* "$A/etc/xdg/"
cp -R "$ROOT/modes/macos/config/skel/." "$A/etc/skel/"
for v in gtk-3.0 gtk-4.0; do mkdir -p "$A/etc/$v"; cp "$ROOT/modes/macos/config/$v/settings.ini" "$A/etc/$v/"; done

# Instalador (Calamares).
mkdir -p "$A/etc/calamares"
cp -R "$ROOT/calamares/." "$A/etc/calamares/"
cp "$ROOT/branding/logo.svg" "$A/etc/calamares/branding/brisa/logo.svg"
if [[ "$BRISA_ID" != brisa ]]; then mv "$A/etc/calamares/branding/brisa" "$A/etc/calamares/branding/$BRISA_ID"; fi

# Papel de parede (pacote de wallpaper do Plasma).
W="$A/usr/share/wallpapers/$BRISA_ID"; mkdir -p "$W/contents/images"
printf '{"KPlugin":{"Id":"%s","Name":"%s","License":"CC-BY-SA-4.0"}}\n' "$BRISA_ID" "$BRISA_NAME" > "$W/metadata.json"
if command -v rsvg-convert >/dev/null; then
  rsvg-convert -w 1920 -h 1080 "$ROOT/branding/wallpaper.svg" -o "$W/contents/images/1920x1080.png"
  rsvg-convert -w 1366 -h 768 "$ROOT/branding/wallpaper.svg" -o "$W/contents/images/1366x768.png"
else
  cp "$ROOT/branding/wallpaper.svg" "$W/contents/images/1920x1080.svg"
fi

if [[ -d "$tmp/profile" ]]; then (cd "$tmp/profile" && tar -cf - .) | (cd "$OUT" && tar -xf -); fi

ID_UPPER="$(printf '%s' "$BRISA_ID" | tr '[:lower:]' '[:upper:]')"
{ grep -rlI '@BRISA_' "$OUT" 2>/dev/null || true; } | while IFS= read -r f; do
  BN="$BRISA_NAME" BI="$BRISA_ID" BU="$ID_UPPER" BA="$BRISA_ACCENT" perl -pi -e \
    's/\@BRISA_NAME\@/$ENV{BN}/g; s/\@BRISA_ID_UPPER\@/$ENV{BU}/g; s/\@BRISA_ID\@/$ENV{BI}/g; s/\@BRISA_ACCENT\@/$ENV{BA}/g' "$f"
done
echo "perfil montado em $OUT"
