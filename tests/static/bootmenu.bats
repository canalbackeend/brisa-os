#!/usr/bin/env bats
# Menus de boot e tela de login com a identidade da distro.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  R="$BATS_TEST_TMPDIR/releng"
  mkdir -p "$R/airootfs" "$R/efiboot/loader/entries" "$R/syslinux" "$R/grub"
  printf 'title    Arch Linux install medium (%%ARCH%%, UEFI)\n' > "$R/efiboot/loader/entries/01-archiso-linux.conf"
  printf 'MENU LABEL Arch Linux install medium (%%ARCH%%, BIOS)\nMENU TITLE Arch Linux\n' > "$R/syslinux/archiso_sys-linux.cfg"
  printf 'menuentry "Arch Linux install medium (%%ARCH%%, UEFI)" {\n}\n' > "$R/grub/grub.cfg"
  : > "$BATS_TEST_TMPDIR/keep"
  RELENG_KEEP="$BATS_TEST_TMPDIR/keep" run "$ROOT/scripts/assemble-profile.sh" "$R" "$BATS_TEST_TMPDIR/p"
  P="$BATS_TEST_TMPDIR/p"
}

@test "nenhum título de boot diz Arch Linux" {
  [ "$status" -eq 0 ]
  run grep -rl 'Arch Linux' "$P/efiboot" "$P/syslinux" "$P/grub"
  [ "$status" -eq 1 ]
}

@test "títulos de boot usam o nome do branding" {
  grep -q 'Brisa Live' "$P/efiboot/loader/entries/01-archiso-linux.conf"
  grep -q 'Brisa Live' "$P/syslinux/archiso_sys-linux.cfg"
  grep -q 'Brisa Live' "$P/grub/grub.cfg"
}

@test "tela de login usa tema breeze com o papel de parede da distro" {
  grep -qx 'Current=breeze' "$P/airootfs/etc/sddm.conf.d/30-brisa-tema.conf"
  grep -q '^background=/usr/share/wallpapers/brisa/contents/images/' "$P/airootfs/usr/share/sddm/themes/breeze/theme.conf.user"
}

@test "guia do usuário cobre gravar, BIOS, Secure Boot, testar e instalar" {
  g="$ROOT/docs/guia.md"
  for t in balenaEtcher "Secure Boot" "shasum -a 256" "Instalar" "Releases"; do grep -q "$t" "$g" || { echo "faltando: $t"; false; }; done
}

@test "I5: sessão live com 2G de espaço gravável em todas as entradas de boot" {
  printf 'options  archisobasedir=%%INSTALL_DIR%% archisosearchuuid=%%ARCHISO_UUID%%\n' >> "$R/efiboot/loader/entries/01-archiso-linux.conf"
  printf 'APPEND archisobasedir=%%INSTALL_DIR%% archisosearchuuid=%%ARCHISO_UUID%%\n' >> "$R/syslinux/archiso_sys-linux.cfg"
  printf '    linux /%%INSTALL_DIR%%/boot/x86_64/vmlinuz-linux archisobasedir=%%INSTALL_DIR%% archisosearchuuid=%%ARCHISO_UUID%%\n' >> "$R/grub/grub.cfg"
  RELENG_KEEP="$BATS_TEST_TMPDIR/keep" run "$ROOT/scripts/assemble-profile.sh" "$R" "$BATS_TEST_TMPDIR/p2"
  for f in efiboot/loader/entries/01-archiso-linux.conf syslinux/archiso_sys-linux.cfg grub/grub.cfg; do
    grep -q 'archisobasedir=.* cow_spacesize=2G' "$BATS_TEST_TMPDIR/p2/$f" || { echo "sem cow_spacesize: $f"; false; }
  done
}

@test "I6: workflow roda também no branch de trabalho; Release só no main" {
  W="$ROOT/.github/workflows/build-iso.yml"
  grep -q 'fase1-macos' "$W"
  grep -q "github.ref == 'refs/heads/main'" "$W"
}
