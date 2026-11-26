#!/usr/bin/env bash
# Autoteste: serviço de atalhos estilo Mac (keyd) ativo.
if [[ "$(systemctl is-active keyd 2>/dev/null)" == active ]]; then
  echo "BRISA:keyd=running"
else
  echo "BRISA:keyd=parado"
fi
