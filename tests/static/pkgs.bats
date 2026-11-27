#!/usr/bin/env bats
# Pacotes próprios e do AUR: sempre pinados; nada de marcas de terceiros.

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"; }

@test "existem os quatro pacotes de tema" {
  for p in brisa-mactahoe-gtk brisa-mactahoe-kde brisa-mactahoe-icons brisa-mactahoe-cursors; do
    [ -f "$ROOT/pkgs/$p/PKGBUILD" ]
  done
}

@test "toda fonte git dos PKGBUILDs está pinada em SHA de 40 hex" {
  for f in "$ROOT"/pkgs/*/PKGBUILD; do
    grep -q 'git+https://' "$f" || continue
    run grep -E 'git\+https://[^"]*' -o "$f"
    for src in $output; do [[ "$src" =~ \#commit=[0-9a-f]{40}$ ]]; done
  done
}

@test "pacotes de tema removem logos de terceiros" {
  for p in brisa-mactahoe-gtk brisa-mactahoe-kde brisa-mactahoe-icons; do
    grep -q 'brisa_strip_trademarks' "$ROOT/pkgs/$p/PKGBUILD"
  done
}

@test "aur/packages.txt: nome + commit de 40 hex, ckbcomp antes de calamares" {
  run grep -vE '^\s*(#|$)' "$ROOT/aur/packages.txt"
  for line in "${lines[@]}"; do [[ "$line" =~ ^[a-z0-9.+_-]+\ [0-9a-f]{40}$ ]]; done
  ck=$(grep -n '^ckbcomp ' "$ROOT/aur/packages.txt" | cut -d: -f1)
  ca=$(grep -n '^calamares ' "$ROOT/aur/packages.txt" | cut -d: -f1)
  [ -n "$ck" ] && [ -n "$ca" ] && [ "$ck" -lt "$ca" ]
}

@test "pacman.conf de montagem tem o repo [brisa] local" {
  grep -qx '\[brisa\]' "$ROOT/archiso/pacman.conf"
  grep -qx 'Server = file:///repo' "$ROOT/archiso/pacman.conf"
}

@test "strip-trademarks remove arquivos de marca e mantém o resto" {
  d="$BATS_TEST_TMPDIR/t"; mkdir -p "$d/a"
  touch "$d/a/activities-apple.svg" "$d/a/distributor-logo-windows.svg" "$d/a/start-here.svg" "$d/a/folder.svg" "$d/a/AppleLogo.png"
  run "$ROOT/pkgs/brisa-strip-trademarks.sh" "$d"
  [ "$status" -eq 0 ]
  [ -f "$d/a/folder.svg" ]
  [ ! -e "$d/a/activities-apple.svg" ] && [ ! -e "$d/a/distributor-logo-windows.svg" ] && [ ! -e "$d/a/start-here.svg" ] && [ ! -e "$d/a/AppleLogo.png" ]
}

@test "tema GTK não depende de gtk-engine-murrine (fora dos repositórios oficiais)" {
  run grep -q 'gtk-engine-murrine' "$ROOT/pkgs/brisa-mactahoe-gtk/PKGBUILD"
  [ "$status" -eq 1 ]
}

@test "tema GTK usa os pacotes prontos de release/ (o install.sh depende de sudo/logname)" {
  f="$ROOT/pkgs/brisa-mactahoe-gtk/PKGBUILD"
  run grep -q 'install.sh' "$f"
  [ "$status" -eq 1 ]
  grep -q 'release/MacTahoe-Light.tar.xz' "$f"
  grep -q 'release/MacTahoe-Dark.tar.xz' "$f"
}
