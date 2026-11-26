#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Programas: Chromium (VA-API + H.264 no YouTube), player, loja Flatpak, atualizador.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  A="$ROOT/archiso/airootfs"
  BIN="$A/usr/bin/brisa-assistir-no-player"
}

@test "política do Chromium é JSON válido e força a extensão enhanced-h264ify" {
  f="$A/etc/chromium/policies/managed/brisa.json"
  jq -e . "$f" >/dev/null
  jq -e '.ExtensionInstallForcelist | index("omkfmpieigblcllmkgbflkikinpkodlk;https://clients2.google.com/service/update2/crx")' "$f" >/dev/null
}

@test "flags do Chromium ativam decodificação por GPU (VA-API) e Wayland" {
  f="$A/etc/skel/.config/chromium-flags.conf"
  grep -q 'AcceleratedVideoDecodeLinuxGL' "$f"
  grep -qx -- '--ozone-platform-hint=auto' "$f"
}

@test "Flathub configurado como remoto do sistema" {
  grep -qx 'Url=https://dl.flathub.org/repo/' "$A/etc/flatpak/remotes.d/flathub.flatpakrepo"
  grep -q '^GPGKey=' "$A/etc/flatpak/remotes.d/flathub.flatpakrepo"
}

@test "pacotes: chromium, mpv, yt-dlp, discover, flatpak, wl-clipboard; sem packagekit; atualizador no AUR" {
  for p in chromium mpv yt-dlp discover flatpak wl-clipboard libnotify arch-update; do
    grep -qx "$p" "$ROOT/archiso/packages.x86_64" || { echo "faltando $p"; false; }
  done
  run ! grep -qx 'packagekit-qt6' "$ROOT/archiso/packages.x86_64"
  grep -Eq '^arch-update [0-9a-f]{40}$' "$ROOT/aur/packages.txt"
}

@test "atalho Assistir no player existe" {
  grep -qx 'Exec=brisa-assistir-no-player' "$A/usr/share/applications/brisa-assistir-no-player.desktop"
}

player() {
  F="$BATS_TEST_TMPDIR/bin"; mkdir -p "$F"
  printf '#!/bin/sh\necho "mpv $*" >> "%s/calls"\n' "$BATS_TEST_TMPDIR" > "$F/mpv"
  printf '#!/bin/sh\necho "notify $*" >> "%s/calls"\n' "$BATS_TEST_TMPDIR" > "$F/notify-send"
  printf '#!/bin/sh\nprintf "%%s" "$CLIP"\n' > "$F/wl-paste"
  chmod +x "$F"/*
  PATH="$F:$PATH" run "$BIN" "$@"
}

@test "abre URL https no mpv" {
  player https://youtu.be/abc
  [ "$status" -eq 0 ]
  grep -qx 'mpv https://youtu.be/abc' "$BATS_TEST_TMPDIR/calls"
}

@test "sem argumento usa a área de transferência" {
  CLIP="https://www.youtube.com/watch?v=xyz" player
  [ "$status" -eq 0 ]
  grep -qx 'mpv https://www.youtube.com/watch?v=xyz' "$BATS_TEST_TMPDIR/calls"
}

@test "URL inválida: avisa em português e sai com 1, sem chamar o mpv" {
  player "ftp://x"
  [ "$status" -eq 1 ]
  grep -q 'notify .*link' "$BATS_TEST_TMPDIR/calls"
  run ! grep -q '^mpv' "$BATS_TEST_TMPDIR/calls"
}

@test "área de transferência vazia também é inválida" {
  CLIP="" player
  [ "$status" -eq 1 ]
}
