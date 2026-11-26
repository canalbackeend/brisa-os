#!/usr/bin/env bats
# brisa-selftest: imprime BRISA:boot=ok e roda selftest.d em ordem.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  BIN="$ROOT/archiso/airootfs/usr/local/bin/brisa-selftest"
  D="$BATS_TEST_TMPDIR/selftest.d"; mkdir -p "$D"
  SERIAL="$BATS_TEST_TMPDIR/serial"; : > "$SERIAL"
}

@test "escreve boot=ok e saídas dos scripts, em ordem, na serial" {
  printf '#!/bin/sh\necho BRISA:b=2\n' > "$D/20-b.sh"; printf '#!/bin/sh\necho BRISA:a=1\n' > "$D/10-a.sh"
  chmod +x "$D"/*.sh
  BRISA_SELFTEST_DIR="$D" BRISA_SERIAL="$SERIAL" run "$BIN"
  [ "$status" -eq 0 ]
  [ "$(cat "$SERIAL")" = "$(printf 'BRISA:boot=ok\nBRISA:a=1\nBRISA:b=2\nBRISA:selftest=done')" ]
}

@test "script que falha vira marcador de erro e não interrompe os demais" {
  printf '#!/bin/sh\nexit 3\n' > "$D/10-ruim.sh"; printf '#!/bin/sh\necho BRISA:ok=1\n' > "$D/20-bom.sh"
  chmod +x "$D"/*.sh
  BRISA_SELFTEST_DIR="$D" BRISA_SERIAL="$SERIAL" run "$BIN"
  grep -qx 'BRISA:erro=10-ruim.sh' "$SERIAL"
  grep -qx 'BRISA:ok=1' "$SERIAL"
}
