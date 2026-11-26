#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Instalador: nunca apaga disco sozinho, funciona offline, padrões do Brasil, cabe em 1366x768.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  C="$ROOT/calamares"
}

@test "partição: sem escolha inicial automática, manual permitido, ext4 padrão" {
  f="$C/modules/partition.conf"
  grep -qx 'initialPartitioningChoice: none' "$f"
  grep -qx 'allowManualPartitioning: true' "$f"
  grep -qx 'defaultFileSystemType: "ext4"' "$f"
}

@test "welcome não exige internet" {
  f="$C/modules/welcome.conf"
  run sed -n '/^ *required:/,/^ *[a-zA-Z]*:$/p' "$f"
  [[ "$output" != *internet* ]]
  grep -q 'storage' <<< "$output"
}

@test "nenhum módulo da sequência baixa pacotes da rede" {
  run ! grep -Eq '^\s*- (packages|netinstall|pacstrap)$' "$C/settings.conf"
}

@test "padrões: fuso America/Sao_Paulo, locale pt_BR" {
  grep -qx 'region:   "America"' "$C/modules/locale.conf"
  grep -qx 'zone:     "Sao_Paulo"' "$C/modules/locale.conf"
  grep -q 'pt_BR.UTF-8' "$C/modules/locale.conf"
}

@test "bootloader GRUB cobre EFI (com fallback) e BIOS" {
  grep -qx 'efiBootLoader: "grub"' "$C/modules/bootloader.conf"
  grep -qx 'installEFIFallback: true' "$C/modules/bootloader.conf"
  for p in grub efibootmgr os-prober calamares; do grep -qx "$p" "$ROOT/archiso/packages.x86_64"; done
}

@test "sequência remove o usuário live e roda a limpeza" {
  grep -qx '  - removeuser' "$C/settings.conf"
  grep -qx '  - shellprocess@limpeza' "$C/settings.conf"
  grep -qx 'username: live' "$C/modules/removeuser.conf"
  grep -q 'brisa-pos-instalacao ${ROOT}' "$C/modules/shellprocess-limpeza.conf"
}

@test "janela do instalador cabe em 1366x768" {
  line=$(grep '^windowSize:' "$C/branding/brisa/branding.desc")
  w=$(sed -E 's/.*: *([0-9]+)px, *([0-9]+)px.*/\1/' <<< "$line"); h=$(sed -E 's/.*: *([0-9]+)px, *([0-9]+)px.*/\2/' <<< "$line")
  [ "$w" -le 1366 ] && [ "$h" -le 700 ]
}

@test "atalho Instalar no live chama o calamares como root" {
  grep -qx 'Exec=sudo -E calamares' "$ROOT/archiso/airootfs/usr/share/applications/brisa-instalar.desktop"
}

@test "C1: shellprocess usa \${ROOT} (sintaxe do Calamares 3.4), não @@ROOT@@" {
  run grep -l '@@ROOT@@' "$C"/modules/*.conf
  [ "$status" -eq 1 ]
  grep -q 'brisa-pos-instalacao ${ROOT}' "$C/modules/shellprocess-limpeza.conf"
}

@test "C2: todo pacote removido no chroot está na ISO" {
  cmd=$(grep -o 'pacman -Rns --noconfirm [a-z0-9 .+_-]*' "$C/modules/shellprocess-chroot.conf" | sed 's/pacman -Rns --noconfirm //')
  for p in $cmd; do grep -qx "$p" "$ROOT/archiso/packages.x86_64" || { echo "não está na ISO: $p"; false; }; done
}

@test "C3: CI instala python antes de compilar o Calamares (módulos Python)" {
  grep -E '^pacman -Syu .*\bpython\b' "$ROOT/scripts/ci-build.sh"
}

@test "C3: selftest exige os módulos Python do Calamares" {
  M="$BATS_TEST_TMPDIR/mods"; mkdir -p "$M/unpackfs"; : > "$M/unpackfs/module.desc"
  F="$BATS_TEST_TMPDIR/bin"; mkdir -p "$F"; printf '#!/bin/sh\n' > "$F/calamares"; chmod +x "$F/calamares"
  : > "$BATS_TEST_TMPDIR/settings.conf"
  PATH="$F:$PATH" BRISA_CALAMARES_MODULES="$M" BRISA_CALAMARES_SETTINGS="$BATS_TEST_TMPDIR/settings.conf" \
    run "$ROOT/archiso/airootfs/usr/lib/brisa/selftest.d/40-calamares.sh"
  [[ "$output" == *"BRISA:calamares=ausente"* ]]
  mkdir -p "$M/bootloader"; : > "$M/bootloader/module.desc"
  PATH="$F:$PATH" BRISA_CALAMARES_MODULES="$M" BRISA_CALAMARES_SETTINGS="$BATS_TEST_TMPDIR/settings.conf" \
    run "$ROOT/archiso/airootfs/usr/lib/brisa/selftest.d/40-calamares.sh"
  [[ "$output" == *"BRISA:calamares=present"* ]]
}

@test "C4: unpackfs copia a imagem já montada (funciona com copytoram)" {
  grep -q 'source: "/run/archiso/airootfs"' "$C/modules/unpackfs.conf"
  grep -q 'sourcefs: "file"' "$C/modules/unpackfs.conf"
}

@test "I3: ferramentas do instalador na ISO (rsync, dosfstools, e2fsprogs, btrfs-progs)" {
  for p in rsync dosfstools e2fsprogs btrfs-progs; do grep -qx "$p" "$ROOT/archiso/packages.x86_64" || { echo "faltando $p"; false; }; done
}
