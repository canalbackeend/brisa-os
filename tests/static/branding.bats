#!/usr/bin/env bats
# Branding: fonte única em branding/brisa.conf, saídas geradas por render-branding.sh

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  OUT="$BATS_TEST_TMPDIR/out"
}

@test "render-branding gera os-release com nome e ID da distro" {
  run "$ROOT/scripts/render-branding.sh" "$OUT"
  [ "$status" -eq 0 ]
  grep -qx 'NAME="Brisa"' "$OUT/os-release"
  grep -qx 'ID=brisa' "$OUT/os-release"
  grep -qx 'ID_LIKE=arch' "$OUT/os-release"
  [ "$(cat "$OUT/brisa-name.txt")" = "Brisa" ]
}

@test "trocar BRISA_NAME no conf muda a saída" {
  conf="$BATS_TEST_TMPDIR/brisa.conf"
  sed 's/^BRISA_NAME=.*/BRISA_NAME="Outra"/; s/^BRISA_ID=.*/BRISA_ID="outra"/' "$ROOT/branding/brisa.conf" > "$conf"
  BRISA_CONF="$conf" run "$ROOT/scripts/render-branding.sh" "$OUT"
  [ "$status" -eq 0 ]
  grep -qx 'NAME="Outra"' "$OUT/os-release"
  grep -qx 'ID=outra' "$OUT/os-release"
}

@test "render-branding sem argumento falha com uso" {
  run "$ROOT/scripts/render-branding.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"uso:"* ]]
}
