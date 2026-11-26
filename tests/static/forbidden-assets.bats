#!/usr/bin/env bats
# Nada de arquivos da Apple ou da Microsoft no repositório.

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"; }

list_files() {
  (cd "$ROOT" && find . -type f -not -path './.git/*' -not -path './.superpowers/*' -not -path './out/*' -not -path './work/*' -not -path './tests/*' -not -path './docs/*')
}

@test "nenhum nome de arquivo proibido" {
  run bash -c "$(declare -f list_files); ROOT='$ROOT'; list_files | grep -Ei 'sf-?pro|sfns|segoe|apple-logo|windows-logo|\.icns$' || true"
  [ -z "$output" ]
}

@test "nenhum SVG com título de marca registrada" {
  run bash -c "cd '$ROOT' && grep -rliE '<title>[^<]*(apple|microsoft|windows)' --include='*.svg' . --exclude-dir=.git --exclude-dir=.superpowers || true"
  [ -z "$output" ]
}

@test "arte própria existe" {
  [ -f "$ROOT/branding/logo.svg" ]
  [ -f "$ROOT/branding/wallpaper.svg" ]
}
