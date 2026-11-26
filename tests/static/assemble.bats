#!/usr/bin/env bats
# assemble-profile.sh: releng (só a lista permitida) + archiso/ + branding.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  R="$BATS_TEST_TMPDIR/releng"; OUT="$BATS_TEST_TMPDIR/profile"
  mkdir -p "$R/airootfs/etc/mkinitcpio.d" "$R/airootfs/etc/mkinitcpio.conf.d" "$R/airootfs/etc/systemd/system/multi-user.target.wants" "$R/efiboot/loader/entries" "$R/syslinux" "$R/grub"
  echo preset > "$R/airootfs/etc/mkinitcpio.d/linux.preset"
  echo hooks > "$R/airootfs/etc/mkinitcpio.conf.d/archiso.conf"
  echo iwd > "$R/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service"
  echo "title Arch Linux install medium" > "$R/efiboot/loader/entries/01-archiso-linux.conf"
  echo "MENU LABEL x" > "$R/syslinux/archiso_sys-linux.cfg"
  echo "menuentry" > "$R/grub/grub.cfg"
  printf 'etc/mkinitcpio.d/linux.preset\netc/mkinitcpio.conf.d/archiso.conf\n' > "$BATS_TEST_TMPDIR/keep.txt"
}

@test "copia só o permitido do releng e aplica o modelo com branding" {
  RELENG_KEEP="$BATS_TEST_TMPDIR/keep.txt" run "$ROOT/scripts/assemble-profile.sh" "$R" "$OUT"
  [ "$status" -eq 0 ]
  [ -f "$OUT/airootfs/etc/mkinitcpio.d/linux.preset" ]
  [ ! -e "$OUT/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service" ]
  [ -f "$OUT/efiboot/loader/entries/01-archiso-linux.conf" ]
  grep -q '^iso_name="brisa"' "$OUT/profiledef.sh"
  grep -qx 'NAME="Brisa"' "$OUT/airootfs/etc/os-release"
  run grep -rl '@BRISA_' "$OUT"
  [ "$status" -eq 1 ]
}

@test "falha se item da lista permitida sumiu do releng" {
  echo 'etc/nao-existe' >> "$BATS_TEST_TMPDIR/keep.txt"
  RELENG_KEEP="$BATS_TEST_TMPDIR/keep.txt" run "$ROOT/scripts/assemble-profile.sh" "$R" "$OUT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"etc/nao-existe"* ]]
}
