#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Modo macOS: tecla Super faz o papel do ⌘ (keyd, sistêmico, sem internet).

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  K="$ROOT/modes/macos/keyd/default.conf"
}

# valor mapeado para <tecla> dentro da seção [<camada>]
map() { awk -v s="[$1]" -v k="$2" '$0==s{f=1;next} /^\[/{f=0} f && $1==k && $2=="=" {print $3}' "$K"; }

@test "vale para todos os teclados" {
  grep -qx '\[ids\]' "$K"
  [ "$(awk '/^\[ids\]/{getline; print}' "$K")" = "*" ]
}

@test "⌘ + letras → equivalentes com Ctrl" {
  for k in z a s f t w n o p r l; do [ "$(map meta $k)" = "C-$k" ] || { echo "meta+$k = $(map meta $k)"; false; }; done
}

@test "copiar/colar/recortar usam Ctrl+Insert/Shift+Insert/Shift+Delete (funcionam também no terminal)" {
  [ "$(map meta c)" = "C-insert" ]
  [ "$(map meta v)" = "S-insert" ]
  [ "$(map meta x)" = "S-delete" ]
}

@test "⌘Q fecha, ⌘Espaço busca, ⌘Tab alterna apps" {
  [ "$(map meta q)" = "A-f4" ]
  [ "$(map meta space)" = "A-space" ]
  [ "$(map meta tab)" = "A-tab" ]
}

@test "⌘⇧3 tela inteira e ⌘⇧4 região (Spectacle)" {
  [ "$(map meta+shift 3)" = "S-print" ]
  [ "$(map meta+shift 4)" = "M-S-print" ]
}

@test "montagem instala a configuração e habilita o keyd" {
  R="$BATS_TEST_TMPDIR/r"; mkdir -p "$R/airootfs"; : > "$BATS_TEST_TMPDIR/keep"
  RELENG_KEEP="$BATS_TEST_TMPDIR/keep" run "$ROOT/scripts/assemble-profile.sh" "$R" "$BATS_TEST_TMPDIR/p"
  [ "$status" -eq 0 ]
  cmp "$K" "$BATS_TEST_TMPDIR/p/airootfs/etc/keyd/default.conf"
  grep -qx keyd "$ROOT/archiso/packages.x86_64"
  [ "$(readlink "$ROOT/archiso/airootfs/etc/systemd/system/multi-user.target.wants/keyd.service")" = "/usr/lib/systemd/system/keyd.service" ]
}

@test "selftest 30-atalhos informa keyd ativo" {
  F="$BATS_TEST_TMPDIR/bin"; mkdir -p "$F"
  printf '#!/bin/sh\n[ "$2" = keyd ] && echo active\n' > "$F/systemctl"; chmod +x "$F/systemctl"
  PATH="$F:$PATH" run "$ROOT/archiso/airootfs/usr/lib/brisa/selftest.d/30-atalhos.sh"
  [[ "$output" == *"BRISA:keyd=running"* ]]
}
