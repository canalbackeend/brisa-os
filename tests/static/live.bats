#!/usr/bin/env bats
# Sessão live: Plasma Wayland com login automático do usuário "live".

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  E="$ROOT/archiso/airootfs/etc"
  PK="$ROOT/archiso/packages.x86_64"
}

@test "autologin do usuário live na sessão plasma (Wayland)" {
  f="$E/sddm.conf.d/10-brisa-live.conf"
  grep -qx 'User=live' "$f"
  grep -qx 'Session=plasma' "$f"
}

@test "SDDM usa greeter Wayland (sem depender de Xorg)" {
  grep -qx 'DisplayServer=wayland' "$E/sddm.conf.d/20-brisa-wayland.conf"
  grep -q '^CompositorCommand=kwin_wayland' "$E/sddm.conf.d/20-brisa-wayland.conf"
}

@test "usuário live criado por sysusers, no grupo wheel, com home do skel" {
  grep -Eq '^u live 1000 ' "$E/sysusers.d/brisa-live.conf"
  grep -Eq '^m live wheel$' "$E/sysusers.d/brisa-live.conf"
  grep -Eq '^C /home/live ' "$E/tmpfiles.d/brisa-live.conf"
  grep -qx 'live ALL=(ALL) NOPASSWD: ALL' "$E/sudoers.d/brisa-live"
}

@test "indexador Baloo desligado por padrão" {
  grep -qx 'Indexing-Enabled=false' "$E/skel/.config/baloofilerc"
}

@test "alvo gráfico, SDDM e NetworkManager habilitados; bluetooth não" {
  [ "$(readlink "$E/systemd/system/default.target")" = "/usr/lib/systemd/system/graphical.target" ]
  [ "$(readlink "$E/systemd/system/display-manager.service")" = "/usr/lib/systemd/system/sddm.service" ]
  [ -L "$E/systemd/system/multi-user.target.wants/NetworkManager.service" ]
  [ ! -e "$E/systemd/system/bluetooth.target.wants/bluetooth.service" ]
}

@test "pacotes essenciais da spec presentes" {
  for p in libva-intel-driver intel-media-driver plasma-desktop kwin sddm networkmanager pipewire wireplumber inter-font ttf-jetbrains-mono dolphin konsole spectacle bluez; do
    grep -qx "$p" "$PK" || { echo "faltando: $p"; false; }
  done
}

@test "selftest 10-plasma detecta plasmashell em Wayland" {
  P="$BATS_TEST_TMPDIR/proc"; mkdir -p "$P/42" "$P/7"
  echo plasmashell > "$P/42/comm"; printf 'A=1\0XDG_SESSION_TYPE=wayland\0' > "$P/42/environ"
  echo bash > "$P/7/comm"; : > "$P/7/environ"
  BRISA_PROC="$P" BRISA_WAIT=1 BRISA_RAM_DELAY=0 BRISA_LIVE_HOME="$BATS_TEST_TMPDIR" \
    run "$ROOT/archiso/airootfs/usr/lib/brisa/selftest.d/10-plasma.sh"
  [[ "$output" == *"BRISA:plasma=ok"* ]]
}

@test "selftest 10-plasma acusa sessão X11 ou ausência" {
  P="$BATS_TEST_TMPDIR/proc"; mkdir -p "$P/42"
  echo plasmashell > "$P/42/comm"; printf 'XDG_SESSION_TYPE=x11\0' > "$P/42/environ"
  BRISA_PROC="$P" BRISA_WAIT=1 BRISA_RAM_DELAY=0 BRISA_LIVE_HOME="$BATS_TEST_TMPDIR" \
    run "$ROOT/archiso/airootfs/usr/lib/brisa/selftest.d/10-plasma.sh"
  [[ "$output" == *"BRISA:plasma=falhou"* ]]
}

@test "selftest 10-plasma informa baloo desligado" {
  mkdir -p "$BATS_TEST_TMPDIR/.config"; printf '[Basic Settings]\nIndexing-Enabled=false\n' > "$BATS_TEST_TMPDIR/.config/baloofilerc"
  BRISA_PROC="$BATS_TEST_TMPDIR/vazio" BRISA_WAIT=1 BRISA_RAM_DELAY=0 BRISA_LIVE_HOME="$BATS_TEST_TMPDIR" \
    run "$ROOT/archiso/airootfs/usr/lib/brisa/selftest.d/10-plasma.sh"
  [[ "$output" == *"BRISA:baloo=off"* ]]
}
