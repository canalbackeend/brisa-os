#!/usr/bin/env bats
# Perfil archiso: modelo em archiso/ (+ partes herdadas do releng na montagem).

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  P="$ROOT/archiso"
}

@test "profiledef usa placeholders do branding, x86_64, BIOS e UEFI" {
  grep -q '^iso_name="@BRISA_ID@"' "$P/profiledef.sh"
  grep -q '^arch="x86_64"' "$P/profiledef.sh"
  grep -Eq "^bootmodes=\(.*'bios\.syslinux'" "$P/profiledef.sh"
  grep -Eq "^bootmodes=\(.*'uefi\.systemd-boot'" "$P/profiledef.sh"
}

@test "lista de pacotes não tem meta-pacotes nem serviços proibidos" {
  run grep -xE 'plasma|kde-applications|kde-applications-meta|plasma-meta|akonadi|kdeconnect|plasma-welcome|kuserfeedback|packagekit-qt6' "$P/packages.x86_64"
  [ "$status" -eq 1 ]
}

@test "idioma, teclado e fuso do Brasil" {
  grep -qx 'LANG=pt_BR.UTF-8' "$P/airootfs/etc/locale.conf"
  grep -qx 'KEYMAP=br-abnt2' "$P/airootfs/etc/vconsole.conf"
  grep -qx 'pt_BR.UTF-8 UTF-8' "$P/airootfs/etc/locale.gen"
  [ "$(readlink "$P/airootfs/etc/localtime")" = "/usr/share/zoneinfo/America/Sao_Paulo" ]
}

@test "autoteste habilitado apenas no live" {
  grep -q 'ConditionPathExists=/run/archiso' "$P/airootfs/etc/systemd/system/brisa-selftest.service"
  [ -L "$P/airootfs/etc/systemd/system/multi-user.target.wants/brisa-selftest.service" ]
}

@test "nenhum arquivo do perfil escreve o nome da distro literalmente" {
  run grep -rl 'Brisa' "$P"
  [ "$status" -eq 1 ]
}
