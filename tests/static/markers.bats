#!/usr/bin/env bats
# check-markers.sh <log> chave=valor... → 0 só se todos aparecem.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  LOG="$BATS_TEST_TMPDIR/log"
  printf 'lixo\r\nBRISA:boot=ok\r\n[  5.1] kernel\nBRISA:plasma=ok\n' > "$LOG"
}

@test "todos presentes (com CRLF da serial) → 0" {
  run "$ROOT/tests/boot/check-markers.sh" "$LOG" boot=ok plasma=ok
  [ "$status" -eq 0 ]
}

@test "faltando → 1 e lista o que faltou" {
  run "$ROOT/tests/boot/check-markers.sh" "$LOG" boot=ok macos_dock=ok
  [ "$status" -eq 1 ]
  [[ "$output" == *"macos_dock=ok"* ]]
}

@test "valor diferente não conta" {
  run "$ROOT/tests/boot/check-markers.sh" "$LOG" plasma=falhou
  [ "$status" -eq 1 ]
}
