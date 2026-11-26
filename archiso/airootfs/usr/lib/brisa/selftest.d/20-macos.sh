#!/usr/bin/env bash
# Autoteste do modo macOS no live: menu global, dock e botões de janela à esquerda.
set -u
H="${BRISA_LIVE_HOME:-/home/live}"
XDG="${BRISA_XDG:-/etc/xdg}"
WAIT="${BRISA_WAIT:-180}"
APPLETS="$H/.config/plasma-org.kde.plasma.desktop-appletsrc"

for (( i = 0; i < WAIT; i += 5 )); do
  grep -q '^plugin=org.kde.plasma.icontasks' "$APPLETS" 2>/dev/null && break
  (( WAIT > 1 )) && sleep 5
done

check() { if grep -qx "$2" "$3" 2>/dev/null; then echo "BRISA:$1=ok"; else echo "BRISA:$1=falhou"; fi; }
check macos_appmenu 'plugin=org.kde.plasma.appmenu' "$APPLETS"
check macos_dock 'plugin=org.kde.plasma.icontasks' "$APPLETS"

left="$(grep -h '^ButtonsOnLeft=' "$H/.config/kwinrc" "$XDG/kwinrc" 2>/dev/null | head -1)"
if [[ "$left" == ButtonsOnLeft=X* ]]; then echo "BRISA:macos_buttons_left=ok"; else echo "BRISA:macos_buttons_left=falhou"; fi
