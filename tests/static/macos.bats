#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Modo macOS: look-and-feel org.brisa.macos, padrões do sistema e brisa-aplicar-modo.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  M="$ROOT/modes/macos"
  LNF="$M/look-and-feel/org.brisa.macos"
  JS="$LNF/contents/layouts/org.kde.plasma.desktop-layout.js"
}

@test "layout: barra superior com menu global e dock inferior flutuante centralizado" {
  grep -q 'top.location = "top"' "$JS"
  grep -q '"org.kde.plasma.appmenu"' "$JS"
  grep -q 'dock.location = "bottom"' "$JS"
  grep -q 'dock.floating = true' "$JS"
  grep -q 'dock.alignment = "center"' "$JS"
  grep -q '"org.kde.plasma.icontasks"' "$JS"
  grep -q '"org.kde.plasma.trash"' "$JS"
}

@test "dock fixa os apps da spec na ordem e Instalar só no live" {
  order=$(grep -o 'applications:[a-zA-Z0-9._-]*\.desktop' "$JS" | tr '\n' ' ')
  [ "$order" = "applications:org.kde.dolphin.desktop applications:chromium.desktop applications:mpv.desktop applications:org.kde.kate.desktop applications:org.kde.konsole.desktop applications:org.kde.discover.desktop applications:systemsettings.desktop applications:brisa-instalar.desktop " ]
  grep -q 'applicationExists("calamares")' "$JS"
}

@test "relógio no formato dia-da-semana + hora" {
  grep -q '"customDateFormat", "ddd"' "$JS"
}

@test "kwinrc: semáforo à esquerda (fechar, minimizar, zoom), blur ligado, wobbly/cubo desligados" {
  f="$M/config/xdg/kwinrc"
  grep -qx 'ButtonsOnLeft=XIA' "$f"
  grep -qx 'ButtonsOnRight=' "$f"
  grep -qx 'theme=__aurorae__svg__MacTahoe-Light' "$f"
  grep -qx 'blurEnabled=true' "$f"
  grep -qx 'wobblywindowsEnabled=false' "$f"
  grep -qx 'cubeEnabled=false' "$f"
}

@test "kdeglobals: fontes Inter 10 / JetBrains Mono 10, ícones e cores MacTahoe, Kvantum, LnF próprio" {
  f="$M/config/xdg/kdeglobals"
  grep -q '^font=Inter,10' "$f"
  grep -q '^fixed=JetBrains Mono,10' "$f"
  grep -qx 'Theme=MacTahoe-light' "$f"
  grep -qx 'ColorScheme=MacTahoeLight' "$f"
  grep -qx 'widgetStyle=kvantum' "$f"
  grep -qx 'LookAndFeelPackage=org.brisa.macos' "$f"
}

@test "cursor, tema Plasma, Kvantum e GTK MacTahoe" {
  grep -qx 'cursorTheme=MacTahoe-cursors' "$M/config/xdg/kcminputrc"
  grep -qx 'name=MacTahoe-Light' "$M/config/xdg/plasmarc"
  grep -qx 'theme=MacTahoe' "$M/config/skel/.config/Kvantum/kvantum.kvconfig"
  grep -qx 'gtk-theme-name=MacTahoe-Light' "$M/config/gtk-3.0/settings.ini"
  grep -qx 'gtk-font-name=Inter 10' "$M/config/gtk-3.0/settings.ini"
}

aplicar() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  unset XDG_CONFIG_HOME
  FAKE="$BATS_TEST_TMPDIR/bin"; mkdir -p "$FAKE"
  printf '#!/bin/sh\necho "$0 $*" >> "%s/calls"\n' "$BATS_TEST_TMPDIR" > "$FAKE/plasma-apply-lookandfeel"
  cp "$FAKE/plasma-apply-lookandfeel" "$FAKE/qdbus6"; chmod +x "$FAKE"/*
  PATH="$FAKE:$PATH" BRISA_MODES_DIR="$ROOT/modes" run "$ROOT/scripts/brisa-aplicar-modo" "$@"
}

@test "brisa-aplicar-modo macos grava o modo, copia configs e aplica o LnF" {
  aplicar macos
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.config/brisa/modo")" = "macos" ]
  grep -qx 'ButtonsOnLeft=XIA' "$HOME/.config/kwinrc"
  [ -f "$HOME/.config/Kvantum/kvantum.kvconfig" ]
  grep -q 'plasma-apply-lookandfeel -a org.brisa.macos --resetLayout' "$BATS_TEST_TMPDIR/calls"
}

@test "brisa-aplicar-modo é idempotente" {
  aplicar macos; aplicar macos
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.config/brisa/modo")" = "macos" ]
}

@test "brisa-aplicar-modo --sem-reiniciar-shell não aplica o LnF" {
  aplicar macos --sem-reiniciar-shell
  [ "$status" -eq 0 ]
  run ! grep -q 'plasma-apply-lookandfeel' "$BATS_TEST_TMPDIR/calls" 2>/dev/null
}

@test "brisa-aplicar-modo rejeita modo desconhecido em português" {
  aplicar windows95
  [ "$status" -ne 0 ]
  [[ "$output" == *"modo desconhecido"* ]]
}

@test "montagem coloca LnF, modos, script e papel de parede no airootfs" {
  R="$BATS_TEST_TMPDIR/releng"; mkdir -p "$R/airootfs"
  : > "$BATS_TEST_TMPDIR/keep"
  RELENG_KEEP="$BATS_TEST_TMPDIR/keep" run "$ROOT/scripts/assemble-profile.sh" "$R" "$BATS_TEST_TMPDIR/p"
  [ "$status" -eq 0 ]
  A="$BATS_TEST_TMPDIR/p/airootfs"
  [ -f "$A/usr/share/plasma/look-and-feel/org.brisa.macos/metadata.json" ]
  [ -x "$A/usr/bin/brisa-aplicar-modo" ]
  [ -f "$A/etc/xdg/kwinrc" ]
  [ -f "$A/etc/skel/.config/Kvantum/kvantum.kvconfig" ]
  [ -f "$A/etc/gtk-3.0/settings.ini" ]
  ls "$A/usr/share/wallpapers/brisa/contents/images/"1920x1080.*
}

@test "selftest 20-macos reconhece menu global, dock e botões à esquerda" {
  H="$BATS_TEST_TMPDIR/h"; X="$BATS_TEST_TMPDIR/xdg"; mkdir -p "$H/.config" "$X"
  printf '[Containments][2]\nplugin=org.kde.panel\n[Containments][2][Applets][5]\nplugin=org.kde.plasma.appmenu\n[Containments][9][Applets][3]\nplugin=org.kde.plasma.icontasks\n' > "$H/.config/plasma-org.kde.plasma.desktop-appletsrc"
  printf '[org.kde.kdecoration2]\nButtonsOnLeft=XIA\n' > "$X/kwinrc"
  BRISA_LIVE_HOME="$H" BRISA_XDG="$X" BRISA_WAIT=1 run "$ROOT/archiso/airootfs/usr/lib/brisa/selftest.d/20-macos.sh"
  [[ "$output" == *"BRISA:macos_appmenu=ok"* ]]
  [[ "$output" == *"BRISA:macos_dock=ok"* ]]
  [[ "$output" == *"BRISA:macos_buttons_left=ok"* ]]
}

@test "selftest 20-macos acusa painel sem menu global" {
  H="$BATS_TEST_TMPDIR/h"; mkdir -p "$H/.config"
  printf '[Containments][9][Applets][3]\nplugin=org.kde.plasma.taskmanager\n' > "$H/.config/plasma-org.kde.plasma.desktop-appletsrc"
  BRISA_LIVE_HOME="$H" BRISA_XDG="$BATS_TEST_TMPDIR/nada" BRISA_WAIT=1 run "$ROOT/archiso/airootfs/usr/lib/brisa/selftest.d/20-macos.sh"
  [[ "$output" == *"BRISA:macos_appmenu=falhou"* ]]
  [[ "$output" == *"BRISA:macos_dock=falhou"* ]]
}
