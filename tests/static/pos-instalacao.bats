#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# brisa-pos-instalacao <root>: tira do sistema instalado tudo o que é só do live.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  BIN="$ROOT/archiso/airootfs/usr/bin/brisa-pos-instalacao"
  T="$BATS_TEST_TMPDIR/alvo"; BM="$BATS_TEST_TMPDIR/bootmnt"
  mkdir -p "$T"/etc/{sddm.conf.d,sysusers.d,tmpfiles.d,sudoers.d,mkinitcpio.d,mkinitcpio.conf.d} \
    "$T"/etc/systemd/system/multi-user.target.wants "$T"/usr/share/applications "$T"/usr/local/bin "$T"/usr/lib/brisa/selftest.d "$T"/boot \
    "$BM/arch/boot/x86_64"
  for f in etc/sddm.conf.d/10-brisa-live.conf etc/sddm.conf.d/20-brisa-wayland.conf etc/sysusers.d/brisa-live.conf etc/tmpfiles.d/brisa-live.conf \
           etc/sudoers.d/brisa-live usr/share/applications/brisa-instalar.desktop etc/systemd/system/brisa-selftest.service \
           usr/local/bin/brisa-selftest usr/lib/brisa/selftest.d/10-plasma.sh etc/mkinitcpio.conf.d/archiso.conf \
           etc/systemd/system/pacman-init.service etc/systemd/system/etc-pacman.d-gnupg.mount; do echo x > "$T/$f"; done
  ln -s /etc/systemd/system/brisa-selftest.service "$T/etc/systemd/system/multi-user.target.wants/brisa-selftest.service"
  ln -s /etc/systemd/system/pacman-init.service "$T/etc/systemd/system/multi-user.target.wants/pacman-init.service"
  printf 'archiso preset\n' > "$T/etc/mkinitcpio.d/linux.preset"
  printf '[options]\nHoldPkg = pacman\n\n[core]\nInclude = x\n\n[brisa]\nSigLevel = Optional TrustAll\nServer = file:///repo\n\n[extra]\nInclude = x\n' > "$T/etc/pacman.conf"
  echo kernel > "$BM/arch/boot/x86_64/vmlinuz-linux"
  mkdir -p "$T/usr/lib/modules/6.12.1-arch1-1"; echo kernel > "$T/usr/lib/modules/6.12.1-arch1-1/vmlinuz"
}

@test "remove itens do live e mantém o greeter Wayland" {
  BRISA_BOOTMNT="$BM" run "$BIN" "$T"
  [ "$status" -eq 0 ]
  for f in etc/sddm.conf.d/10-brisa-live.conf etc/sysusers.d/brisa-live.conf etc/tmpfiles.d/brisa-live.conf etc/sudoers.d/brisa-live \
           usr/share/applications/brisa-instalar.desktop etc/systemd/system/brisa-selftest.service usr/local/bin/brisa-selftest \
           usr/lib/brisa/selftest.d etc/mkinitcpio.conf.d/archiso.conf etc/systemd/system/pacman-init.service \
           etc/systemd/system/etc-pacman.d-gnupg.mount; do
    [ ! -e "$T/$f" ] || { echo "sobrou $f"; false; }
  done
  [ ! -L "$T/etc/systemd/system/multi-user.target.wants/brisa-selftest.service" ]
  [ ! -L "$T/etc/systemd/system/multi-user.target.wants/pacman-init.service" ]
  [ -f "$T/etc/sddm.conf.d/20-brisa-wayland.conf" ]
}

@test "pacman.conf fica sem [brisa] e com os outros repositórios" {
  BRISA_BOOTMNT="$BM" run "$BIN" "$T"
  run ! grep -q 'brisa' "$T/etc/pacman.conf"
  grep -qx '\[core\]' "$T/etc/pacman.conf"
  grep -qx '\[extra\]' "$T/etc/pacman.conf"
}

@test "preset do mkinitcpio volta ao padrão e o kernel é copiado para /boot" {
  BRISA_BOOTMNT="$BM" run "$BIN" "$T"
  grep -qx "PRESETS=('default' 'fallback')" "$T/etc/mkinitcpio.d/linux.preset"
  run ! grep -q archiso "$T/etc/mkinitcpio.d/linux.preset"
  [ "$(cat "$T/boot/vmlinuz-linux")" = kernel ]
}

@test "rodar duas vezes não falha" {
  BRISA_BOOTMNT="$BM" run "$BIN" "$T"; BRISA_BOOTMNT="$BM" run "$BIN" "$T"
  [ "$status" -eq 0 ]
}

@test "recusa raiz inexistente ou '/'" {
  run "$BIN" /
  [ "$status" -ne 0 ]
  run "$BIN" "$BATS_TEST_TMPDIR/nao-existe"
  [ "$status" -ne 0 ]
}

@test "C4: kernel copiado do próprio sistema instalado (sem depender do pendrive)" {
  rm -rf "$BM"; mkdir -p "$T/usr/lib/modules/6.12.1-arch1-1"; echo kalvo > "$T/usr/lib/modules/6.12.1-arch1-1/vmlinuz"
  BRISA_BOOTMNT="$BM" run "$BIN" "$T"
  [ "$status" -eq 0 ]
  [ "$(cat "$T/boot/vmlinuz-linux")" = kalvo ]
}

@test "C4: falha alto se nenhum kernel acabar em /boot" {
  rm -rf "$BM" "$T/usr/lib/modules"
  BRISA_BOOTMNT="$BM" run "$BIN" "$T"
  [ "$status" -ne 0 ]
  [[ "$output" == *"kernel"* ]]
}

@test "C5: root fica bloqueado (sem senha vazia) no sistema instalado" {
  printf 'root::14871::::::\nbin:!*:19000::::::\n' > "$T/etc/shadow"
  BRISA_BOOTMNT="$BM" run "$BIN" "$T"
  [ "$status" -eq 0 ]
  grep -q '^root:!\*:' "$T/etc/shadow"
  grep -qx 'bin:!\*:19000::::::' "$T/etc/shadow"
}
